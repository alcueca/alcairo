use core::starknet::{ ContractAddress };

#[starknet::interface]
pub trait IERC721<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn tokenURI(self: @TContractState) -> felt252;
    fn ownerOf(self: @TContractState, tokenId: felt252) -> ContractAddress;
    fn isApproved(self: @TContractState, tokenId: felt252, operator: ContractAddress) -> bool;
    fn deployer(self: @TContractState) -> ContractAddress;
    
    fn mint(ref self: TContractState);
    fn transfer(ref self: TContractState, to: ContractAddress, tokenId: felt252);
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, tokenId: felt252);
    fn approve(ref self: TContractState, operator: ContractAddress, tokenId: felt252);
}

#[starknet::contract]
pub mod ERC721 {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use core::starknet::{ ContractAddress, get_caller_address };

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transferred: Transferred,
        Approved: Approved,
        Minted: Minted,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Minted {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub tokenId: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Transferred {
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub tokenId: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Approved {
        #[key]
        pub operator: ContractAddress,
        pub tokenId: felt252,
    }

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        tokenURI: felt252,
        decimals: u8,
        lastTokenId: felt252,
        ownerOf: Map<felt252, ContractAddress>,
        approvals: Map<felt252, Map<ContractAddress, bool>>,
        deployer: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, name_: felt252, symbol_: felt252, tokenURI_: felt252) {
        self.name.write(name_);
        self.symbol.write(symbol_);
        self.tokenURI.write(tokenURI_);
        let deployer = get_caller_address();
        self.deployer.write(deployer);
    }

    #[abi(embed_v0)]
    impl ERC721Impl of super::IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        
        fn tokenURI(self: @ContractState) -> felt252 {
            self.tokenURI.read()
        }

        fn deployer(self: @ContractState) -> ContractAddress {
            self.deployer.read()
        }
        
        fn ownerOf(self: @ContractState, tokenId: felt252) -> ContractAddress {
            self.ownerOf.entry(tokenId).read()
        }

        fn isApproved(self: @ContractState, tokenId: felt252, operator: ContractAddress) -> bool {
            self.approvals.entry(tokenId).entry(operator).read()
        }

        fn mint(ref self: ContractState) {
            let lastTokenId_ = self.lastTokenId.read();
            self.ownerOf.entry(lastTokenId_).write(get_caller_address());
            self.lastTokenId.write(lastTokenId_ + 1);
            self.emit(Minted { owner: get_caller_address(), tokenId: lastTokenId_ });
        }

        fn approve(ref self: ContractState, operator: ContractAddress, tokenId: felt252) {
            assert(get_caller_address() == self.ownerOf.entry(tokenId).read(), 'Only token owner');
            self.approvals.entry(tokenId).entry(operator).write(true);
            self.emit(Approved { operator: operator, tokenId: tokenId });
        }        

        fn transfer(ref self: ContractState, to: ContractAddress, tokenId: felt252) {
            let from = get_caller_address();
            assert(
                from == self.ownerOf.entry(tokenId).read(),
                'Only token owner'
            );
            _transfer(ref self, from, to, tokenId);
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: felt252) {
            let caller = get_caller_address();
            assert(
                caller == from ||
                self.approvals.entry(tokenId).entry(caller).read() != true,
                'Only owner or operator'
            );
            _transfer(ref self, from, to, tokenId);
        }
    }

    fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: felt252) {
        self.ownerOf.entry(tokenId).write(to);
        self.emit(Transferred { from: from, to: to, tokenId: tokenId });
    }
}
