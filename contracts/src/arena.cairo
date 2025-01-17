#[starknet::contract]
mod Arena {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[derive(Drop, Serde, Copy)]
    struct GladiatorEntry {
        sender_address: ContractAddress,
        gladiator: Gladiator,
    }

    #[storage]
    struct Storage {
        eth_dispatcher: IERC20Dispatcher,
        strk_dispatcher: IERC20Dispatcher,
        usdt_dispatcher: IERC20Dispatcher,
        gladiators: LegacyMap<u32, GladiatorEntry>,
        current_count: u32,
        next_round_time: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        eth_address: ContractAddress,
        strk_address: ContractAddress,
        usdt_address: ContractAddress,
        _round_interval: u64,
        _entry_fee: u256,
    ) { // self.eth_dispatcher.write(IERC20Dispatcher { contract_address: eth_address });
    // self.strk_dispatcher.write(IERC20Dispatcher { contract_address: strk_address });
    // self.usdt_dispatcher.write(IERC20Dispatcher { contract_address: usdt_address });

    // self.round_interval.write(_round_interval);
    // self.entry_fee.write(_entry_fee);
    // self.next_round_time.write(get_block_timestamp() + _round_interval);
    }

    #[external(v0)]
    fn enter_arena(ref self: ContractState) { // TODO:
    // workflow :

    // - Constructor : choppe les adresses des contrats eth, strk, usdt
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
    }

    #[external(v0)]
    fn battle_round(ref self: ContractState) {}
}
