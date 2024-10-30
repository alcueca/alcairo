use core::starknet::{ ContractAddress };

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    
    fn transferOwnership(ref self: TContractState, newOwner: ContractAddress);
}

#[starknet::component]
pub mod Ownable {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use core::starknet::{ ContractAddress, get_caller_address };

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OwnershipTransferred {
        #[key]
        pub newOwner: ContractAddress,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[embeddable_as(Ownable)]
    impl OwnableImpl<TContractState, +HasComponent<TContractState>> of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }  

        fn transferOwnership(ref self: ComponentState<TContractState>, newOwner: ContractAddress) {
            self.onlyOwner();
            self.emit(OwnershipTransferred { newOwner: newOwner });
        }
    }

    #[generate_trait]
    pub impl InternalImpl<TContractState, +HasComponent<TContractState>> of InternalTrait<TContractState> {
        fn initialize(ref self: ComponentState<TContractState>, owner_: ContractAddress) {
            self.owner.write(owner_);
            self.emit(OwnershipTransferred { newOwner: owner_ });
        }

        fn onlyOwner(self: @ComponentState<TContractState>) {
            assert(self.owner.read() == get_caller_address(), 'OnlyOwner');
        }  
    }
}
