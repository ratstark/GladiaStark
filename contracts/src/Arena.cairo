#[starknet::interface]
pub trait IArena<T> {
    fn enter_arena(ref self: T, tokenId: u256);
    fn entrance_payment(ref self: T, amount: u256);
    fn time_left(self: @T) -> u64;
    fn battle_round(ref self: T);
    fn getGladiator(ref self: T, tokenId: u256);
    fn start_season(ref self: T);
    fn get_price_entry_eth(ref self: T) -> u128;
}

#[starknet::contract]
mod Arena {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess, Map, Vec
    };
    use gladiastark::Gladiator_ERC721::{IGladiatorDispatcher};
    use gladiastark::helper::PragmaHelper::{IPragmaHelperDispatcher, IPragmaHelperDispatcherTrait};
    use gladiastark::helper::RandomnessHelper::{IRandomnessDispatcher};
    use super::IArena;

    const ETH_USD: felt252 = 19514442401534788; // ETH/USD to felt252
    const STRK_USD: felt252 = 6004514686061859652; // STRK/USD

    #[storage]
    struct Storage {
        eth_dispatcher: IERC20Dispatcher,
        strk_dispatcher: IERC20Dispatcher,
        pragma_dispatcher: IPragmaHelperDispatcher,
        gladiator_dispatcher: IGladiatorDispatcher,
        random_dispatcher: IRandomnessDispatcher,
        price_eth: u128,
        price_strk: u128,
        gladiators: Vec<IGladiatorDispatcher>,
        current_count: u32,
        season_interval: u64,
        entry_fee: u256,
        pool_map: Map<ContractAddress, u256>,
        total_pool: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        eth_address: ContractAddress,
        strk_address: ContractAddress,
        pragma_address: ContractAddress,
        gladiator_address: ContractAddress,
        randomness_address: ContractAddress,
        season_interval: u64,
        _entry_fee: u256,
    ) {
        self.current_count.write(0);
        self.pragma_dispatcher.write(IPragmaHelperDispatcher { contract_address: pragma_address });
        self.random_dispatcher.write(IRandomnessDispatcher { contract_address: randomness_address });
        self.eth_dispatcher.write(IERC20Dispatcher { contract_address: eth_address });
        self.strk_dispatcher.write(IERC20Dispatcher { contract_address: strk_address });
        self.gladiator_dispatcher.write(IGladiatorDispatcher { contract_address: gladiator_address });
        self.price_eth.write(self.pragma_dispatcher.read().get_token_per_usd(ETH_USD));
        self.price_strk.write(self.pragma_dispatcher.read().get_token_per_usd(STRK_USD));
        self.season_interval.write(season_interval + (168 * 60 * 60));
        self.entry_fee.write(_entry_fee);
        self.total_pool.write(0);
    }

    #[abi(embed_v0)]
    impl ArenaImpl of IArena<ContractState> {
        fn enter_arena(ref self: ContractState, tokenId: u256) { 
            self.entrance_payment(self.entry_fee.read());
            self.getGladiator(tokenId);
            self.start_season();

        }
        fn start_season(ref self: ContractState) {
            assert!(self.time_left() == 0, "Season as started");
            while self.current_count.read() > 1 {
                self.battle_round();
            }
        }

        fn entrance_payment(ref self: ContractState, amount: u256) {
            let sender = get_caller_address();
            let contract_address = get_contract_address();
            let token = self.eth_dispatcher.read();
            let sender_balance = token.balance_of(sender);
            assert(sender_balance >= amount, 'Insufficient balance');

            let allowance = token.allowance(sender, contract_address);
            assert(allowance >= amount, 'Insufficient allowance');

            assert!(self.time_left() > 0, "Season as started");
            token.transfer_from(sender, contract_address, amount);
            let pool = self.pool_map.read(sender);
            self.pool_map.write(sender, pool + amount);
            self.total_pool.write(self.total_pool.read() + amount);
        }

        fn getGladiator(ref self: ContractState, tokenId: u256) {
            let gladiator: IGladiatorDispatcher = self.gladiator_dispatcher.read();
            assert(gladiator.owner_of(tokenId) == get_caller_address(), "You are not the owner of this gladiator");
            gladiator.safe_transfer_from(get_caller_address(), get_contract_address(), tokenId);
            self.current_count.write(self.current_count.read() + 1);
            self.gladiators.append().write(gladiator);
        }

        fn battle_round(ref self: ContractState) {
            let gladiator1Id = self.random_dispatcher.read().get_random_fighter(self.current_count.read()).into();
            let gladiator2Id = self.random_dispatcher.read().get_random_fighter(self.current_count.read()).into();
            if self.random_dispatcher.read().get_random_number() % 2 == 0 {
                self.gladiators.at(gladiator1Id).read().burn();
                self.current_count.write(self.current_count.read() - 1);
            } else {
                self.gladiators.at(gladiator2Id).read().burn();
                self.current_count.write(self.current_count.read() - 1);
            }
            
        }

        fn time_left(self: @ContractState) -> u64 {
            let deadline = self.season_interval.read();
            let current_time = get_block_timestamp();
            if current_time >= deadline {
                return 0;
            }
            return deadline - current_time;
        }
        fn get_price_entry_eth(ref self: ContractState) -> u128 {
            self.price_eth.read() 
        }
    }
}
