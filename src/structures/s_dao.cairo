use core::starknet::ContractAddress;
use starknet::class_hash::ClassHash;


#[derive(Drop, Serde, starknet::Store)]
pub struct User {
    is_dao: bool,
    approved: bool,
    region: Option<ByteArray>,
    details: ByteArray,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct RealestateIndex {
    region: ByteArray,
    index_value: felt252,
    month_over_month_change: felt252,
    year_over_year_change: felt252,
    median_price: felt252,
    trend: felt252,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct RealestateIndexData {
    index: RealestateIndex,
    proposer: ContractAddress,
    timestamp: u64,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Listing {
    id: u256,
    details: ByteArray,
    hash: felt252,
    region: ByteArray,
    owner: ContractAddress,
}
