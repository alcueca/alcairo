use starknet::{
    ContractAddress,
};

use snforge_std::{
    declare,
    ContractClassTrait,
    DeclareResultTrait,
};

use cairomate::erc20_ownable::{ IERC20OwnableDispatcher, IERC20OwnableDispatcherTrait };
use cairomate::ownable_component::{ IOwnableDispatcher };

const NAME: felt252 = 'ClaimToken';
const SYMBOL: felt252 = 'CTK';
const DECIMALS: u8 = 18;

fn deploy_contract() -> (ContractAddress, IERC20OwnableDispatcher, IOwnableDispatcher) {
    let contract = declare("ERC20Ownable").unwrap().contract_class();
    let mut parameters = ArrayTrait::new();
    parameters.append(NAME);
    parameters.append(SYMBOL);
    parameters.append(DECIMALS.try_into().unwrap());
    
    let (contract_address, _) = contract.deploy(@parameters).unwrap();
    (contract_address, IERC20OwnableDispatcher { contract_address }, IOwnableDispatcher { contract_address })
}

#[test]
fn test_constructor_params() {
    let (_, erc20_dispatcher, ownable_dispatcher) = deploy_contract();

    assert(erc20_dispatcher.name() == NAME, 'Invalid name');
    assert(erc20_dispatcher.symbol() == SYMBOL, 'Invalid symbol');
    assert(erc20_dispatcher.decimals() == DECIMALS, 'Invalid decimals');
    
    let deployer = erc20_dispatcher.deployer();
    assert(deployer == ownable_dispatcher.owner(), 'Invalid owner');
}

// #[test]
// fn test_mint() {
//     let (_, erc20_dispatcher, _) = deploy_contract();
// 
//     let holder: ContractAddress = 1234.try_into().unwrap();
// 
//     erc20_dispatcher.mint(holder, 42);
// 
//     let balanceOf = erc20_dispatcher.balanceOf(holder);
//     assert(balanceOf == 42, 'Invalid balance');
// }
// 
// #[test]
// fn test_transferOwnership() {
//     let (_, _, ownable_dispatcher) = deploy_contract();
// 
//     let newOwner: ContractAddress = 'newOwner'.try_into().unwrap();
// 
//     ownable_dispatcher.transferOwnership(newOwner);
// }
