use core::traits::TryInto;
use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Print, Serde)]
struct Gladiator {
    strength: u8,
    speed: u8,
    stamina: u8,
    intelligence: u8,
    agility: u8,
}

