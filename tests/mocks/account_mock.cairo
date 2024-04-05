#[starknet::interface]
trait IAccount<TStorage> {
    fn name(self: @TStorage) -> felt252;
}


#[starknet::contract]
mod MockAccount {
    use super::IAccount;
    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl ERC20Impl of IAccount<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            'mock'
        }
    }
}
