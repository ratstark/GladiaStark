// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.20.0
use starknet::{ContractAddress};

#[starknet::interface]
pub trait IGladiator<T> {
    fn burn(ref self: T, token_id: u256);
    fn mint(ref self: T, recipient: ContractAddress, token_id: u256);
    fn safeMint(ref self: T, recipient: ContractAddress, uri: ByteArray) -> u256;
    fn get_token_uri(self: @T, token_id: u256) -> ByteArray;
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: T, from: ContractAddress, to: ContractAddress, token_id: u256,
    );
    fn _token_uri(self: @T, token_id: u256) -> ByteArray;
    fn set_token_uri(ref self: T, token_id: u256, uri: ByteArray);
}

#[starknet::contract]
pub mod Gladiator {
    use core::num::traits::Zero;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::common::erc2981::{DefaultConfig, ERC2981Component};
    use openzeppelin::token::erc721::{
        ERC721Component, ERC721HooksEmptyImpl, interface::IERC721MetadataCamelOnly,
    };
    use starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess, Map,
    };

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC2981Component, storage: erc2981, event: ERC2981Event);

    // External
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981Impl = ERC2981Component::ERC2981Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981InfoImpl = ERC2981Component::ERC2981InfoImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981AdminOwnableImpl =
        ERC2981Component::ERC2981AdminOwnableImpl<ContractState>;

    // Internal
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl ERC2981InternalImpl = ERC2981Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        id_counter: u128,
        token_uris: Map<u256, ByteArray>,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc2981: ERC2981Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC2981Event: ERC2981Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, default_royalty_receiver: ContractAddress,
    ) {
        let base_uri: ByteArray = "https://white-worried-coral-590.mypinata.cloud/ipfs/";
        self.erc721.initializer("Gladiator", "GLDK", base_uri);
        self.ownable.initializer(owner);
        self.erc2981.initializer(default_royalty_receiver, 0);
    }

    #[abi(embed_v0)]
    impl GladiatorImpl of super::IGladiator<ContractState> {
        fn burn(ref self: ContractState, token_id: u256) {
            self.erc721.update(Zero::zero(), token_id, get_caller_address());
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, token_id: u256) {
            self.ownable.assert_only_owner();
            self.erc721.mint(recipient, token_id);
        }

        fn safeMint(ref self: ContractState, recipient: ContractAddress, uri: ByteArray) -> u256 {
            self.id_counter.write(self.id_counter.read() + 1);
            let token_id: u256 = self.id_counter.read().into();
            self.mint(recipient, token_id);
            self.set_token_uri(token_id, uri);
            token_id
        }

        fn get_token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.token_uris.read(token_id)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721._owner_of(token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256,
        ) {
            self.erc721.transfer(from, to, token_id);
        }
        fn _token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            let base_uri = self.erc721._base_uri();
            if base_uri.len() == 0 {
                Default::default()
            } else {
                let uri = self.token_uris.read(token_id);
                format!("{}{}", base_uri, uri)
            }
        }

        // ERC721URIStorage internal functions,
        fn set_token_uri(ref self: ContractState, token_id: u256, uri: ByteArray) {
            self.token_uris.write(token_id, uri);
        }
    }

    #[abi(embed_v0)]
    impl WrappedIERC721MetadataCamelOnlyImpl of IERC721MetadataCamelOnly<ContractState> {
        // Override tokenURI to use the internal ERC721URIStorage _token_uri function
        fn tokenURI(self: @ContractState, tokenId: u256) -> ByteArray {
            self._token_uri(tokenId)
        }
    }
}
