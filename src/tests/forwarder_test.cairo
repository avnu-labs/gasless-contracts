use avnu::tests::helper::{deploy_forwarder, deploy_mock_token, deploy_mock_account};
use avnu::forwarder::{Forwarder, IForwarderDispatcher, IForwarderDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, class_hash_const};
use starknet::testing::set_contract_address;
use array::{Array, ArrayTrait};

mod GetOwner {
    use super::{deploy_forwarder, IForwarderDispatcherTrait, contract_address_const};

    #[test]
    #[available_gas(2000000)]
    fn should_return_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let expected = contract_address_const::<0x1>();

        // When
        let result = forwarder.get_owner();

        // Then
        assert(result == expected, 'invalid owner');
    }
}

mod TransferOwnership {
    use super::{
        deploy_forwarder, IForwarderDispatcherTrait, contract_address_const, set_contract_address
    };

    #[test]
    #[available_gas(2000000)]
    fn should_change_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let new_owner = contract_address_const::<0x3456>();
        set_contract_address(forwarder.get_owner());

        // When
        let result = forwarder.transfer_ownership(new_owner);

        // Then
        assert(result == true, 'invalid result');
        let owner = forwarder.get_owner();
        assert(owner == new_owner, 'invalid owner');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_caller_is_not_the_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let new_owner = contract_address_const::<0x3456>();
        set_contract_address(contract_address_const::<0x1234>());

        // When & Then
        forwarder.transfer_ownership(new_owner);
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('New owner is the zero address', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_owner_is_0() {
        // Given
        let forwarder = deploy_forwarder();
        let new_owner = contract_address_const::<0x0>();
        set_contract_address(forwarder.get_owner());

        // When & Then
        let result = forwarder.transfer_ownership(new_owner);
    }
}

mod UpgradeClass {
    use super::{
        deploy_forwarder, IForwarderDispatcherTrait, class_hash_const, set_contract_address,
        contract_address_const
    };

    #[test]
    #[available_gas(2000000)]
    fn should_upgrade_class() {
        // Given
        let forwarder = deploy_forwarder();
        let new_class = class_hash_const::<0x3456>();
        set_contract_address(forwarder.get_owner());

        // When
        let result = forwarder.upgrade_class(new_class);

        // Then
        assert(result == true, 'invalid result');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_caller_is_not_the_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let new_class = class_hash_const::<0x3456>();
        set_contract_address(contract_address_const::<0x1234>());

        // When & Then
        forwarder.upgrade_class(new_class);
    }
}

mod GetGasFessRecipient {
    use super::{deploy_forwarder, IForwarderDispatcherTrait, contract_address_const};

    #[test]
    #[available_gas(2000000)]
    fn should_return_gas_fess_recipient() {
        // Given
        let forwarder = deploy_forwarder();
        let expected = contract_address_const::<0x2>();

        // When
        let result = forwarder.get_gas_fees_recipient();

        // Then
        assert(result == expected, 'invalid recipient');
    }
}

mod SetGasFessRecipient {
    use super::{
        deploy_forwarder, IForwarderDispatcherTrait, contract_address_const, class_hash_const,
        set_contract_address
    };

    #[test]
    #[available_gas(2000000)]
    fn should_set_gas_fess_recipient() {
        // Given
        let forwarder = deploy_forwarder();
        let recipient_address = contract_address_const::<0x3>();
        set_contract_address(forwarder.get_owner());

        // When
        let result = forwarder.set_gas_fees_recipient(recipient_address);

        // Then
        assert(result == true, 'invalid result');
        let new_recipient = forwarder.get_gas_fees_recipient();
        assert(new_recipient == recipient_address, 'invalid recipient');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_caller_is_not_the_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let recipient_address = contract_address_const::<0x3>();
        set_contract_address(contract_address_const::<0x1234>());

        // When & Then
        forwarder.set_gas_fees_recipient(recipient_address);
    }
}

mod IsWhitelistedCaller {
    use super::{deploy_forwarder, IForwarderDispatcherTrait, contract_address_const};

    #[test]
    #[available_gas(2000000)]
    fn should_return_a_bool() {
        // Given
        let forwarder = deploy_forwarder();
        let address = contract_address_const::<0x2>();

        // When
        let result = forwarder.is_whitelisted_caller(address);

        // Then
        assert(result == false, 'invalid is_whitelisted_caller');
    }
}

mod SetWhitelistedCaller {
    use super::{
        deploy_forwarder, IForwarderDispatcherTrait, contract_address_const, set_contract_address
    };

    #[test]
    #[available_gas(2000000)]
    fn should_set_whitelisted_caller() {
        // Given
        let forwarder = deploy_forwarder();
        let address = contract_address_const::<0x2>();
        set_contract_address(forwarder.get_owner());

        // When
        let result = forwarder.set_whitelisted_caller(address, true);

        // Then
        assert(result == true, 'invalid result');
        let fees_active = forwarder.is_whitelisted_caller(address);
        assert(fees_active == true, 'invalid fees_active');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_caller_is_not_the_owner() {
        // Given
        let forwarder = deploy_forwarder();
        let address = contract_address_const::<0x2>();
        set_contract_address(contract_address_const::<0x1234>());

        // When & Then
        forwarder.set_whitelisted_caller(address, true);
    }
}

mod Execute {
    use avnu::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{
        deploy_mock_token, deploy_forwarder, IForwarderDispatcherTrait, contract_address_const,
        set_contract_address, Array, ArrayTrait, deploy_mock_account
    };

    #[test]
    #[available_gas(2000000000)]
    fn should_execute() {
        // Given
        let forwarder = deploy_forwarder();
        let caller = contract_address_const::<0x999>();
        set_contract_address(forwarder.get_owner());
        forwarder.set_whitelisted_caller(caller, true);
        let account = deploy_mock_account();
        let account_address = account.contract_address;
        let entrypoint: felt252 = 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60;
        let calldata: Array<felt252> = array![];
        let gas_token = deploy_mock_token(account_address, 10);
        let gas_token_address = gas_token.contract_address;
        let gas_amount: u256 = 1_u256;
        set_contract_address(account_address);
        gas_token.transfer(forwarder.contract_address, gas_amount);
        set_contract_address(caller);

        // When
        let result = forwarder
            .execute(account_address, entrypoint, calldata, gas_token_address, gas_amount);

        // Then
        assert(result == true, 'invalid result');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Caller is not whitelisted', 'ENTRYPOINT_FAILED'))]
    fn should_fail_when_caller_is_not_whitelisted() {
        // Given
        let forwarder = deploy_forwarder();
        let account_address = contract_address_const::<0x1>();
        let entrypoint: felt252 = 0x0;
        let calldata: Array<felt252> = array![0x1, 0x2];
        let gas_token_address = contract_address_const::<0x1>();
        let gas_amount: u256 = 1_u256;
        set_contract_address(contract_address_const::<0x1234>());

        // When & Then
        forwarder.execute(account_address, entrypoint, calldata, gas_token_address, gas_amount);
    }
}
