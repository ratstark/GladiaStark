
#[starknet::interface]
pub trait IRandomness<TContractState> {
        fn get_random_fighter(ref self: TContractState, n:u32)-> u32 ;
        fn get_random_number(ref self: TContractState)-> u32 ;
}   