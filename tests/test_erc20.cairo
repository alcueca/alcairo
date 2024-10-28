use starknet::ContractAddress;
use snforge_std::{
    declare,
    ContractClassTrait,
    DeclareResultTrait,
    start_cheat_caller_address,
    spy_events,
    EventSpyAssertionsTrait
};

// use erc20::IERC20SafeDispatcher;
// use erc20::IERC20SafeDispatcherTrait;
use cairomate::erc20::{ ERC20, IERC20Dispatcher, IERC20DispatcherTrait };

const NAME: felt252 = 'ClaimToken';
const SYMBOL: felt252 = 'CTK';
const DECIMALS: u8 = 18;

fn deploy_contract() -> (ContractAddress, IERC20Dispatcher) {
    let contract = declare("ERC20").unwrap().contract_class();
    let mut parameters = ArrayTrait::new();
    parameters.append(NAME);
    parameters.append(SYMBOL);
    parameters.append(DECIMALS.try_into().unwrap());
    // let parameters = array![NAME, SYMBOL, DECIMALS.try_into().unwrap()]; // Same, but in short with the `array!` macro.
    
    let (contract_address, _) = contract.deploy(@parameters).unwrap();
    (contract_address, IERC20Dispatcher { contract_address })
}

#[test]
fn test_constructor_params() {
    let (_, dispatcher) = deploy_contract();

    assert(dispatcher.name() == NAME, 'Invalid name');
    assert(dispatcher.symbol() == SYMBOL, 'Invalid symbol');
    assert(dispatcher.decimals() == DECIMALS, 'Invalid decimals');
    
    let deployer = dispatcher.deployer();
    assert(dispatcher.balanceOf(deployer) == 1, 'Invalid initial supply');
    assert(dispatcher.allowances(deployer, deployer) == 1, 'Invalid initial allowances');

    // let random: ContractAddress = 1234.try_into().unwrap();
    // println!("{:?}", random);
}

#[test]
fn test_whoami() {
    let (_, dispatcher) = deploy_contract();
    
    let whoami = dispatcher.whoami();

    // println!("I am {:?}", whoami);
}

#[test]
fn test_mint() {
    let (_, dispatcher) = deploy_contract();

    let holder: ContractAddress = 1234.try_into().unwrap();

    dispatcher.mint(holder, 42);

    let balanceOf = dispatcher.balanceOf(holder);
    assert(balanceOf == 42, 'Invalid balance');
}

#[test]
fn test_transfer() {
    let (contract_address, dispatcher) = deploy_contract();

    let deployer = dispatcher.deployer();
    let recipient: ContractAddress = 1234.try_into().unwrap();

    let mut spy = spy_events();

    dispatcher.transfer(recipient, 1);

    spy.assert_emitted(@array![(
        contract_address,
        ERC20::Event::Transfer(
            ERC20::Transfer { from: deployer, to: recipient, value: 1 }
        )
    )]);

    assert(dispatcher.balanceOf(deployer) == 0, 'Invalid sender balance');
    assert(dispatcher.balanceOf(recipient) == 1, 'Invalid recipient balance');
}

#[test]
fn test_approve() {
    let (contract_address, dispatcher) = deploy_contract();

    let deployer = dispatcher.deployer();
    let spender: ContractAddress = 1234.try_into().unwrap();

    let mut spy = spy_events();

    dispatcher.approve(spender, 42);

    spy.assert_emitted(@array![(
        contract_address,
        ERC20::Event::Approval(
            ERC20::Approval { owner: deployer, spender: spender, value: 42 }
        )
    )]);

    let allowance = dispatcher.allowances(deployer, spender);
    assert(allowance == 42, 'Invalid allowance');
}

#[test]
fn test_transfer_from() {
    let (contract_address, dispatcher) = deploy_contract();

    let deployer = dispatcher.deployer();
    let spender: ContractAddress = 'spender'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();

    dispatcher.approve(spender, 1);

    let mut spy = spy_events();

    start_cheat_caller_address( contract_address, spender);
    dispatcher.transfer_from(deployer, recipient, 1);

    spy.assert_emitted(@array![(
        contract_address,
        ERC20::Event::Transfer(
            ERC20::Transfer { from: deployer, to: recipient, value: 1 }
        )
    )]);

    assert(dispatcher.balanceOf(deployer) == 0, 'Invalid sender balance');
    assert(dispatcher.balanceOf(recipient) == 1, 'Invalid recipient balance');
}

// #[test]
// #[feature("safe_dispatcher")]
// fn test_cannot_increase_balance_with_zero_value() {
//     let (_, dispatcher) = deploy_contract();
// 
//     let safe_dispatcher = IERC20SafeDispatcher { dispatcher };
// 
//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');
// 
//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }
