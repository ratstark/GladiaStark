use starknet::ContractAddress;
// Asset IDs for price feeds
const ETH_USD: felt252 = 19514442401534788; // ETH/USD to felt252
const STRK_USD: felt252 = 6004514686061859652; // STRK/USD

#[starknet::interface]
trait IPragmaHelper<TContractState> {
    fn get_asset_price(self: @TContractState, asset_id: felt252) -> u128;
    fn get_token_per_usd(self: @TContractState, asset_id: felt252) -> u128;
}

#[starknet::contract]
mod PragmaHelper {
    use super::{ContractAddress, IPragmaHelper};
    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{DataType, AggregationMode, PragmaPricesResponse};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        pragma_contract: ContractAddress,
        summary_stats: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pragma_address: ContractAddress,
        summary_stats_address: ContractAddress,
    ) {
        self.pragma_contract.write(pragma_address);
        self.summary_stats.write(summary_stats_address);
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
