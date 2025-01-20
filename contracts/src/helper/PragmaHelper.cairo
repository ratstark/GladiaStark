#[starknet::interface]
pub trait IPragmaHelper<TContractState> {
    fn get_asset_price(self: @TContractState, asset_id: felt252) -> u128;
    fn get_token_per_usd(self: @TContractState, asset_id: felt252) -> u128;
}

#[starknet::contract]
pub mod PragmaHelper {
    use starknet::{ContractAddress};
    use super::{IPragmaHelper};
    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{DataType, AggregationMode, PragmaPricesResponse};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        pragma_contract: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pragma_address: ContractAddress,
    ) {
        self.pragma_contract.write(pragma_address);
    }

    #[abi(embed_v0)]
    impl PragmaHelperImpl of IPragmaHelper<ContractState> {
        fn get_asset_price(self: @ContractState, asset_id: felt252) -> u128 {
            let oracle_dispatcher = IPragmaABIDispatcher {
                contract_address: self.pragma_contract.read(),
            };

            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data(DataType::SpotEntry(asset_id), AggregationMode::Median(()));

            output.price
        }

        fn get_token_per_usd(self: @ContractState, asset_id: felt252) -> u128 {
            let price = self.get_asset_price(asset_id);
            // Price is in USD with 8 decimals, so we need to divide 100000000 by the price
            // to get the amount of tokens per 1 USD
            100000000_u128 / price
        }
    }
}
