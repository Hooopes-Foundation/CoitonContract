use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of COITON NFT
// *************************************************************************
#[starknet::interface]
pub trait ICoiton721<TState> {
    fn mint_coiton_nft(ref self: TState, address: ContractAddress);
    fn get_last_minted_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, user: ContractAddress) -> u256;
    fn get_token_mint_timestamp(self: @TState, token_id: u256) -> u64;
}
