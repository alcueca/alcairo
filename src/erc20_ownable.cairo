use core::starknet::{ ContractAddress };

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn balanceOf(self: @TContractState, holder: ContractAddress) -> u128;
    fn allowances(self: @TContractState, holder: ContractAddress, spender: ContractAddress) -> u128;
    fn deployer(self: @TContractState) -> ContractAddress;
    
    fn mint(ref self: TContractState, holder: ContractAddress, amount: u128) -> bool;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u128);
    fn transfer_from(ref self: TContractState, holder: ContractAddress, recipient: ContractAddress, amount: u128);
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u128);
}

#[starknet::contract]
pub mod ERC20Ownable {
    use ownable_component::Ownable::InternalTrait;
use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use core::starknet::{ ContractAddress, get_caller_address };
    use cairomate::ownable_component;

    component!(path: ownable_component::Ownable, storage: ownable, event: OwnableEvent);

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
        OwnableEvent: ownable_component::Ownable::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Transfer {
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub value: u128,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Approval {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub spender: ContractAddress,
        pub value: u128,
    }

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        balanceOf: Map<ContractAddress, u128>,
        allowances: Map<ContractAddress, Map<ContractAddress, u128>>,
        deployer: ContractAddress,
        #[substorage(v0)]
        ownable: ownable_component::Ownable::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, name_: felt252, symbol_: felt252, decimals_: u8) {
        self.name.write(name_);
        self.symbol.write(symbol_);
        self.decimals.write(decimals_);
        let deployer = get_caller_address();
        self.deployer.write(deployer);
        self.ownable.initialize(get_caller_address());

        self.balanceOf.entry(deployer).write(1);
        self.allowances.entry(deployer).entry(deployer).write(1);
    }

    #[abi(embed_v0)]
    impl OwnableImpl = ownable_component::Ownable::Ownable<ContractState>;

    impl OwnableInternalImpl = ownable_component::Ownable::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        
        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }
        
        fn balanceOf(self: @ContractState, holder: ContractAddress) -> u128 {
            self.balanceOf.entry(holder).read()
        }

        fn deployer(self: @ContractState) -> ContractAddress {
            self.deployer.read()
        }

        fn allowances(self: @ContractState, holder: ContractAddress, spender: ContractAddress) -> u128 {
            self.allowances.entry(holder).entry(spender).read()
        }

        fn mint(ref self: ContractState, holder: ContractAddress, amount: u128) -> bool {
            self.ownable.onlyOwner();
            self.balanceOf.entry(holder).write(self.balanceOf.entry(holder).read() + amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u128) {
            let holder = get_caller_address();
            _approve(ref self, holder, spender, amount);
        }        

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u128) {
            let sender = get_caller_address();
            _transfer(ref self, sender, recipient, amount);
        }

        fn transfer_from(ref self: ContractState, holder: ContractAddress, recipient: ContractAddress, amount: u128) {
            let caller = get_caller_address();
            if caller != holder {
                let allowance = self.allowances.entry(holder).entry(caller).read();
                self.allowances.entry(holder).entry(caller).write(allowance - amount);
            }
            _transfer(ref self, holder, recipient, amount);
        }
    }

    fn _approve(ref self: ContractState, holder: ContractAddress, spender: ContractAddress, amount: u128) {
        let current = self.allowances.entry(holder).entry(spender).read();
        self.allowances.entry(holder).entry(spender).write(current + amount);
        self.emit(Approval { owner: holder, spender: spender, value: amount });
    }

    fn _transfer(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u128) {
        self.balanceOf.entry(sender).write(self.balanceOf.entry(sender).read() - amount);
        self.balanceOf.entry(recipient).write(self.balanceOf.entry(recipient).read() + amount);
        self.emit(Transfer { from: sender, to: recipient, value: amount });
    }
}
