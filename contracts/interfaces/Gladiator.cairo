use core::traits::TryInto;
use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Print, Serde)]
struct Gladiator {
    id: u128,
    owner: ContractAddress,
    abilities: Abilities,
}

#[derive(Copy, Drop, Print, Serde, Introspect)]
struct Abilities {
    strength: u8,
    speed: u8,
    stamina: u8,
    intelligence: u8,
    agility: u8,
}

