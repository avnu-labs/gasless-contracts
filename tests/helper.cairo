use avnu::forwarder::{Forwarder, IForwarderDispatcher, IForwarderDispatcherTrait};
use avnu_lib::components::ownable::IOwnableDispatcher;
use avnu_lib::components::whitelist::IWhitelistDispatcher;
use avnu_lib::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use core::integer::{u256, u256_from_felt252, BoundedInt};
use starknet::testing::{set_contract_address, pop_log_raw};
use starknet::{ContractAddress, deploy_syscall, contract_address_const};
use super::mocks::account_mock::{MockAccount, IAccountDispatcher, IAccountDispatcherTrait};
use super::mocks::erc20_mock::ERC20Mock;

fn deploy_mock_token(recipient: ContractAddress, balance: felt252) -> IERC20Dispatcher {
    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    constructor_args.append(recipient.into());
    constructor_args.append(balance);
    constructor_args.append(0x0);
    let (token_address, _) = deploy_syscall(ERC20Mock::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_args.span(), false)
        .expect('token deploy failed');
    return IERC20Dispatcher { contract_address: token_address };
}

fn deploy_mock_account() -> IAccountDispatcher {
    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    let (token_address, _) = deploy_syscall(MockAccount::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_args.span(), false)
        .expect('account deploy failed');
    return IAccountDispatcher { contract_address: token_address };
}

fn deploy_forwarder() -> (IForwarderDispatcher, IOwnableDispatcher, IWhitelistDispatcher) {
    let constructor_args: Array<felt252> = array![0x1, 0x2];
    let (address, _) = deploy_syscall(Forwarder::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_args.span(), false)
        .expect('Forwarder deploy failed');
    pop_log_raw(address).unwrap();
    assert(pop_log_raw(address).is_none(), 'no more events');
    (
        IForwarderDispatcher { contract_address: address },
        IOwnableDispatcher { contract_address: address },
        IWhitelistDispatcher { contract_address: address },
    )
}