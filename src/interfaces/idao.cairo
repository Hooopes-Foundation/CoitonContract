use starknet::{ContractAddress};
use starknet::class_hash::ClassHash;

#[derive(Drop, Serde, starknet::Store)]
pub struct User {
    pub is_dao: bool,
    pub approved: bool,
    pub region: Option<ByteArray>,
    pub details: ByteArray,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct RealestateIndex {
    pub region: ByteArray,
    pub index_value: felt252,
    pub month_over_month_change: felt252,
    pub year_over_year_change: felt252,
    pub median_price: felt252,
    pub trend: felt252,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct RealestateIndexData {
    pub index: RealestateIndex,
    pub proposer: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Listing {
    pub id: u256,
    pub details: ByteArray,
    pub hash: felt252,
    pub region: ByteArray,
    pub owner: ContractAddress,
}

#[starknet::interface]
pub trait IDao<TContractState> {
    fn create_listing(
        ref self: TContractState, region: ByteArray, details: ByteArray, hash: felt252
    );
    fn approve_listing(ref self: TContractState, _id: u256, hash: felt252);
    fn version(self: @TContractState) -> u16;
    fn get_unapproved_listings(self: @TContractState) -> Array<Listing>;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn hash(self: @TContractState, operand: felt252) -> felt252;
    fn get_erc20(self: @TContractState) -> ContractAddress;
    fn get_erc721(self: @TContractState) -> ContractAddress;
    fn get_erc1155(self: @TContractState) -> ContractAddress;
    fn get_listings(self: @TContractState) -> Array<Listing>;
    fn stake_listing_fee(ref self: TContractState);
    fn approve_dao_member(ref self: TContractState, address: ContractAddress);
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
    fn set_erc1155(ref self: TContractState, address: ContractAddress);
    fn set_erc721(ref self: TContractState, address: ContractAddress);
    fn withdraw(ref self: TContractState, amount: u256);
    fn register_user(ref self: TContractState, is_dao: bool, region: ByteArray, details: ByteArray);
    fn get_user(self: @TContractState, address: ContractAddress) -> User;
    fn is_user_registered(self: @TContractState, address: ContractAddress) -> bool;
    fn has_staked(self: @TContractState, address: ContractAddress) -> bool;
    fn get_dao_members(self: @TContractState) -> Array<User>;
    fn get_unapproved_listings_dao_specific(
        self: @TContractState, address: ContractAddress
    ) -> Array<Listing>;
    fn store_realestate_index(ref self: TContractState, indices: Array<RealestateIndexData>);
    fn get_realestate_indices(self: @TContractState) -> Array<RealestateIndexData>;
    fn set_erc20(ref self: TContractState, address: ContractAddress);
    fn get_realestate_indices_by_region(
        self: @TContractState, region: ByteArray
    ) -> Array<RealestateIndexData>;
}
