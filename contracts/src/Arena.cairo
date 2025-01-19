#[starknet::contract]
mod Arena {
    use starknet::storage::{StoragePointerWriteAccess, StorableStoragePointerReadAccess};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use core::starknet::storage::{Map};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use gladia_stark::Gladiator; 
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use super::{IPragmaHelperDispatcher, IVrfProviderDispatcherTrait};
    use cartridge_vrf::IVrfProviderDispatcher;
    use cartridge_vrf::IVrfProviderDispatcherTrait;
    use cartridge_vrf::Source;

    const ONE_DOLLAR_IN_WEI: u256 = 1000000000000000000; // 1e18 for precision

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Stake: Stake,
        GladiatorEntered: GladiatorEntered,
        BattleStarted: BattleStarted,
        BattlePairCreated: BattlePairCreated,
        BattleResult: BattleResult,
    }

    #[derive(Drop, starknet::Event)]
    struct Stake {
        #[key]
        sender: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct GladiatorEntered {
        sender: ContractAddress,
        gladiator_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct BattleStarted {
        timestamp: u64,
        total_gladiators: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct BattlePairCreated {
        gladiator1_id: u32,
        gladiator2_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct BattleResult {
        battle_id: u32,
        winner_id: u32,
        loser_id: u32,
    }

    #[storage]
    struct Storage {
        eth_dispatcher: IERC20Dispatcher,
        strk_dispatcher: IERC20Dispatcher,
        usdt_dispatcher: IERC20Dispatcher,
        gladiators: Map<u32, GladiatorEntered>,
        current_count: u32,
        next_round_time: u64,
        balances: Map<ContractAddress, u256>,
        stake_deadline: u64,
        open_for_withdraw: bool,
        total_staked: u256,
        pragma_helper: IPragmaHelperDispatcher,
        vrf_provider: IVrfProviderDispatcher,
        battle_started: bool,
        battle_pairs: Map<u32, (u32, u32)>,
        battle_pairs_count: u32,
        battle_result: Map<u32, u32>, // Maps battle_id to winner_id
        gladiator_nft: IERC721Dispatcher,
        vrf_provider_address: ContractAddress // Add VRF provider address to storage
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        eth_address: ContractAddress,
        strk_address: ContractAddress,
        usdt_address: ContractAddress,
        pragma_helper_address: ContractAddress,
        gladiator_nft_address: ContractAddress,
        vrf_provider_address: ContractAddress, // Add VRF provider address parameter
        round_interval: u64,
        _entry_fee: u256,
    ) {
        self.eth_dispatcher.write(IERC20Dispatcher { contract_address: eth_address });
        self.strk_dispatcher.write(IERC20Dispatcher { contract_address: strk_address });
        self.usdt_dispatcher.write(IERC20Dispatcher { contract_address: usdt_address });
        self.next_round_time.write(get_block_timestamp() + round_interval);
        self
            .stake_deadline
            .write(get_block_timestamp() + (72 * 60 * 60)); // 72 hours staking period
        self
            .pragma_helper
            .write(IPragmaHelperDispatcher { contract_address: pragma_helper_address });
        self.vrf_provider_address.write(vrf_provider_address);
        self.vrf_provider.write(IVrfProviderDispatcher { contract_address: vrf_provider_address });
        self.gladiator_nft.write(IERC721Dispatcher { contract_address: gladiator_nft_address });
    }

    /// @notice Stakes ETH tokens in the arena
    /// @param amount The amount of ETH tokens to stake
    /// @dev Requires approval for token transfer and active staking period
    #[generate_trait]
    #[abi(per_item)]
    #[external(v0)]
    fn stake(ref self: ContractState, amount: u256) {
        let sender = get_caller_address();
        let contract_address = get_contract_address();
        let token = self.eth_dispatcher.read();

        assert(token.balance_of(sender) >= amount, 'Insufficient balance');
        assert(token.allowance(sender, contract_address) >= amount, 'Insufficient allowance');
        assert(self.time_left() > 0, 'Staking period ended');

        token.transfer_from(sender, contract_address, amount);

        self.balances.write(sender, self.balances.read(sender) + amount);
        self.total_staked.write(self.total_staked.read() + amount);

        self.emit(Stake { sender, amount });
    }

    /// @notice Withdraws staked tokens from the arena
    /// @dev Can only be called when withdrawals are enabled
    #[external(v0)]
    fn withdraw(ref self: ContractState) {
        let sender = get_caller_address();
        assert(self.open_for_withdraw.read(), 'Withdraw not open');

        let amount = self.balances.read(sender);
        assert(amount > 0, 'No balance to withdraw');

        let token = self.eth_dispatcher.read();
        token.transfer(sender, amount);

        self.balances.write(sender, 0);
        self.total_staked.write(self.total_staked.read() - amount);
    }

    /// @notice Returns the time remaining in the staking period
    /// @return u64 Time left in seconds, returns 0 if staking period has ended
    #[external(v0)]
    fn time_left(self: @ContractState) -> u64 {
        let deadline = self.stake_deadline.read();
        let current_time = get_block_timestamp();
        if current_time >= deadline {
            return 0;
        }
        deadline - current_time
    }

    #[derive(Drop, PartialEq)]
    enum TokenType {
        ETH,
        STRK,
    }

    /// @notice Enters a gladiator into the arena using ETH or STRK tokens
    /// @param token_type The type of token to use for entry fee (ETH or STRK)
    /// @param nft_token_id The ID of the NFT token to transfer
    /// @dev Entry fee is equivalent to $1 USD in the chosen token
    #[external(v0)]
    fn enter_arena(ref self: ContractState, token_type: TokenType, nft_token_id: u256) {
        let sender = get_caller_address();
        let contract_address = get_contract_address();

        // First verify NFT ownership and transfer
        let nft = self.gladiator_nft.read();
        assert(nft.owner_of(nft_token_id) == sender, 'Not NFT owner');

        // Transfer NFT to Arena contract
        nft.transfer_from(sender, contract_address, nft_token_id);

        // Continue with token payment logic
        let (token, asset_id) = if token_type == TokenType::ETH {
            (self.eth_dispatcher.read(), ETH_USD)
        } else {
            (self.strk_dispatcher.read(), STRK_USD)
        };

        // Get how much token needed for $1
        let token_needed: u128 = self.pragma_helper.read().get_token_per_usd(asset_id);
        // Convert to u256 and scale to 18 decimals (from 8 decimals)
        let token_amount: u256 = (token_needed.into() * ONE_DOLLAR_IN_WEI) / 100000000;

        // Check if the user has enough tokens
        assert(token.balance_of(sender) >= token_amount, 'Insufficient balance');
        assert(token.allowance(sender, contract_address) >= token_amount, 'Insufficient allowance');

        // Transfer tokens to the arena contract
        token.transfer_from(sender, contract_address, token_amount);

        // Create a new GladiatorEntry with NFT info
        let gladiator_id = self.current_count.read();
        let gladiator_entry = GladiatorEntry {
            sender_address: sender, gladiator: Gladiator { token_id: nft_token_id },
        };

        // Store the GladiatorEntry and increment counter
        self.gladiators.write(gladiator_id, gladiator_entry);
        self.current_count.write(gladiator_id + 1);

        // Emit the GladiatorEntered event
        self.emit(GladiatorEntered { sender, gladiator_id });
    }

    /// @notice Starts the battle phase by creating random pairs of gladiators
    /// @dev Can only be called after staking period ends and requires at least 2 gladiators
    /// @dev Uses VRF for random pair generation
    #[external(v0)]
    fn start_battle(ref self: ContractState) {
        // Check if staking period is over
        assert(self.time_left() == 0, 'Staking period not over');
        assert(!self.battle_started.read(), 'Battle already started');

        let total_gladiators = self.current_count.read();
        assert(total_gladiators > 1, 'Not enough gladiators');

        // Mark battle as started
        self.battle_started.write(true);

        // Create an array of available gladiator IDs
        let mut available_gladiators = ArrayTrait::new();
        let mut i: u32 = 0;
        loop {
            if i >= total_gladiators {
                break;
            }
            available_gladiators.append(i);
            i += 1;
        };

        // Use VRF to create random pairs
        let contract_address = get_contract_address();
        let vrf = self.vrf_provider.read();
        let mut pair_count: u32 = 0;

        while available_gladiators.len() >= 2 {
            // Get random index for first gladiator
            let random1 = vrf.consume_random(Source::Salt(pair_count.into()));
            let idx1 = random1.into() % available_gladiators.len();
            let gladiator1_id = available_gladiators.pop_front().unwrap();

            // Get random index for second gladiator
            let random2 = vrf.consume_random(Source::Salt((pair_count + 1).into()));
            let idx2 = random2.into() % available_gladiators.len();
            let gladiator2_id = available_gladiators.pop_front().unwrap();

            // Store the pair
            self.battle_pairs.write(pair_count, (gladiator1_id, gladiator2_id));
            self.emit(BattlePairCreated { gladiator1_id, gladiator2_id });

            pair_count += 1;
        };

        self.battle_pairs_count.write(pair_count);
        self.emit(BattleStarted { timestamp: get_block_timestamp(), total_gladiators });
    }

    /// @notice Executes a battle round between paired gladiators
    /// @param battle_id The ID of the battle pair to execute
    /// @dev Uses VRF to determine the winner with 50/50 chance
    #[external(v0)]
    fn battle_round(ref self: ContractState, battle_id: u32) {
        // Check if battle has started
        assert(self.battle_started.read(), 'Battle not started');

        // Check if battle_id is valid
        assert(battle_id < self.battle_pairs_count.read(), 'Invalid battle ID');

        // Check if battle hasn't been executed yet
        assert(self.battle_result.read(battle_id) == 0, 'Battle already executed');

        // Get the gladiator pair
        let (gladiator1_id, gladiator2_id) = self.battle_pairs.read(battle_id);

        // Get both gladiator entries to access their NFT token IDs
        let gladiator1 = self.gladiators.read(gladiator1_id);
        let gladiator2 = self.gladiators.read(gladiator2_id);

        // Use VRF to determine winner (50/50 chance)
        let vrf = self.vrf_provider.read();
        let random = vrf.consume_random(Source::Salt(battle_id.into()));

        // If random number is even, gladiator1 wins, if odd, gladiator2 wins
        let (winner_id, loser_id, loser_token_id) = if random % 2 == 0 {
            (gladiator1_id, gladiator2_id, gladiator2.gladiator.token_id)
        } else {
            (gladiator2_id, gladiator1_id, gladiator1.gladiator.token_id)
        };

        // Store the result
        self.battle_result.write(battle_id, winner_id);

        // Burn the losing gladiator's NFT
        let nft = self.gladiator_nft.read();
        nft.burn(loser_token_id);

        // Emit battle result event
        self.emit(BattleResult { battle_id, winner_id, loser_id });
    }
}
