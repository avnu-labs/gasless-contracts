use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IForwarder<TContractState> {
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn upgrade_class(ref self: TContractState, new_class_hash: ClassHash) -> bool;
    fn get_gas_fees_recipient(self: @TContractState) -> ContractAddress;
    fn set_gas_fees_recipient(
        ref self: TContractState, gas_fees_recipient: ContractAddress
    ) -> bool;
    fn is_whitelisted_caller(self: @TContractState, caller: ContractAddress) -> bool;
    fn set_whitelisted_caller(
        ref self: TContractState, caller: ContractAddress, value: bool
    ) -> bool;
    fn execute(
        ref self: TContractState,
        account_address: ContractAddress,
        entrypoint: felt252,
        calldata: Array<felt252>,
        gas_token_address: ContractAddress,
        gas_amount: u256,
    ) -> bool;
}

#[starknet::contract]
mod Forwarder {
    use super::IForwarder;
    use avnu::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{
        call_contract_syscall, ContractAddress, ClassHash, get_caller_address,
        replace_class_syscall, get_contract_address
    };

    #[storage]
    struct Storage {
        owner: ContractAddress,
        gas_fees_recipient: ContractAddress,
        whitelisted_caller: LegacyMap<ContractAddress, bool>,
    }

    #[event]
    #[derive(starknet::Event, Drop, PartialEq)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(starknet::Event, Drop, PartialEq)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, gas_fees_recipient: ContractAddress
    ) {
        self._transfer_ownership(owner);
        self.gas_fees_recipient.write(gas_fees_recipient);
    }

    #[external(v0)]
    impl ForwarderImpl of IForwarder<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.assert_only_owner();
            assert(!new_owner.is_zero(), 'New owner is the zero address');
            self._transfer_ownership(new_owner);
            true
        }

        fn upgrade_class(ref self: ContractState, new_class_hash: ClassHash) -> bool {
            self.assert_only_owner();
            replace_class_syscall(new_class_hash);
            true
        }

        fn get_gas_fees_recipient(self: @ContractState) -> ContractAddress {
            self.gas_fees_recipient.read()
        }

        fn set_gas_fees_recipient(
            ref self: ContractState, gas_fees_recipient: ContractAddress
        ) -> bool {
            self.assert_only_owner();
            self.gas_fees_recipient.write(gas_fees_recipient);
            true
        }

        fn is_whitelisted_caller(self: @ContractState, caller: ContractAddress) -> bool {
            self.whitelisted_caller.read(caller)
        }

        fn set_whitelisted_caller(
            ref self: ContractState, caller: ContractAddress, value: bool
        ) -> bool {
            self.assert_only_owner();
            self.whitelisted_caller.write(caller, value);
            true
        }

        fn execute(
            ref self: ContractState,
            account_address: ContractAddress,
            entrypoint: felt252,
            calldata: Array<felt252>,
            gas_token_address: ContractAddress,
            gas_amount: u256,
        ) -> bool {
            // Check if caller is whitelisted
            let caller = get_caller_address();
            assert(self.is_whitelisted_caller(caller), 'Caller is not whitelisted');

            // Execute the call
            call_contract_syscall(account_address, entrypoint, calldata.span());

            // Collect gas fees
            let contract_address = get_contract_address();
            let gas_token = IERC20Dispatcher { contract_address: gas_token_address };
            let gas_fees_recipient = self.get_gas_fees_recipient();
            gas_token.transfer(gas_fees_recipient, gas_amount);
            let gas_token_balance = gas_token.balanceOf(contract_address);
            gas_token.transfer(account_address, gas_token_balance);

            true
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn assert_only_owner(self: @ContractState) {
            let owner = self.get_owner();
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'Caller is the zero address');
            assert(caller == owner, 'Caller is not the owner');
        }

        fn _transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let previous_owner = self.get_owner();
            self.owner.write(new_owner);
            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }
        fn upgrade_class(ref self: ContractState, new_class_hash: ClassHash) -> bool {
            self.assert_only_owner();
            replace_class_syscall(new_class_hash);
            true
        }
    }
}
