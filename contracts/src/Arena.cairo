#[starknet::interface]
pub trait IArena<T> {
    fn enter_arena(ref self: T, tokenId: u256);
    fn battle_round(ref self: T);
    fn entrance_payment(ref self: T, amount: u256);
    fn time_left(self: @T) -> u64;
}

#[starknet::contract]
mod Arena {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess, Map,
    };
    use gladiastark::Gladiator_ERC721::{IGladiatorDispatcher};
    use gladiastark::helper::PragmaHelper::{IPragmaHelperDispatcher, IPragmaHelperDispatcherTrait};
    use super::IArena;

    const ETH_USD: felt252 = 19514442401534788; // ETH/USD to felt252
    const STRK_USD: felt252 = 6004514686061859652; // STRK/USD

    #[derive(Drop, Serde, Copy)]
    struct GladiatorEntry {
        sender_address: ContractAddress,
        gladiator: IGladiatorDispatcher,
    }

    #[storage]
    struct Storage {
        eth_dispatcher: IERC20Dispatcher,
        strk_dispatcher: IERC20Dispatcher,
        pragma_dispatcher: IPragmaHelperDispatcher,
        price_eth: u128,
        price_strk: u128,
        gladiators: Map<u32, GladiatorEntry>,
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
        season_interval: u64,
        _entry_fee: u256,
    ) {
        self.current_count.write(0);
        self.pragma_dispatcher.write(IPragmaHelperDispatcher { contract_address: pragma_address });
        self.eth_dispatcher.write(IERC20Dispatcher { contract_address: eth_address });
        self.strk_dispatcher.write(IERC20Dispatcher { contract_address: strk_address });
        self.price_eth.write(self.pragma_dispatcher.read().get_token_per_usd(ETH_USD));
        self.price_strk.write(self.pragma_dispatcher.read().get_token_per_usd(STRK_USD));
        self.season_interval.write(season_interval + (168 * 60 * 60));
        self.entry_fee.write(_entry_fee);
        self.total_pool.write(0);
    }

    #[abi(embed_v0)]
    impl ArenaImpl of IArena<ContractState> {
        fn enter_arena(ref self: ContractState, tokenId: u256) { // TODO:
            // workflow :

            // - Constructor : choppe les adresses des contrats eth, strk
            // - Click sur bouton sur le site -> Call de la fonction enter_arena
            //     - approve tx sur le GUI au prealable
            //     - enter_arena :
            //         - check quil y ai assez de tokens chez le user
            //         - transfere les token vers adresse arena
            //         - transfere les NFT a l'adresse de l'arene
            //         - check condition de start OK (toutes les heures)
            //         LOOP
            //         - appel fonction 1v1 :
            //             - random choose 2 gladiators + store leurs idx
            //             - random choose 1 stat + compare stat dessus
            //             - burn looser
            //             - renvoie idx looser (pour supprimer de la map)
            //         - last gladiator -> renvoyé

            //         map créé [index, Struct {sender_address, Gladiator}]
            assert(true, '');
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

        fn battle_round(ref self: ContractState) {}

        fn time_left(self: @ContractState) -> u64 {
            let deadline = self.season_interval.read();
            let current_time = get_block_timestamp();
            if current_time >= deadline {
                return 0;
            }
            return deadline - current_time;
        }
    }
}
