use cartridge_vrf::IVrfProviderDispatcher;
use cartridge_vrf::IVrfProviderDispatcherTrait;
use cartridge_vrf::Source;
use starknet::ContractAddress;
use starknet::get_caller_address;

const VRF_PROVIDER_ADDRESS: ContractAddress = starknet::contract_address_const::0x00be3edf412dd5982aa102524c0b8a0bcee584c5a627ed1db6a7c36922047257();

#[starknet::interface]
pub trait IRandomness<TContractState> {
    fn get_random_fighter(ref self: TContractState, n: u32) -> u32;
    fn get_random_number(ref self: TContractState) -> u32;
}

#[starknet::component]
pub mod randomness_component {
    use super::IVrfProviderDispatcher;
    use super::VRF_PROVIDER_ADDRESS;
    use super::Source;
    use super::get_caller_address;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl Randomness of IRandomness<ContractState> {
        fn get_random_fighter(ref self: ContractState, n: u32) -> u32 {
            let vrf_provider = IVrfProviderDispatcher { contract_address: VRF_PROVIDER_ADDRESS };
            let player_id = get_caller_address();
            let random_value = vrf_provider.consume_random(Source::Nonce(player_id));
            (random_value % n).try_into().unwrap()
        }

        fn get_random_number(ref self: TContractState) -> u32 {
            let vrf_provider = IVrfProviderDispatcher { contract_address: VRF_PROVIDER_ADDRESS };
            let player_id = get_caller_address();
            let random_value = vrf_provider.consume_random(Source::Nonce(player_id));
            random_value.try_into().unwrap()
        }
    }
}