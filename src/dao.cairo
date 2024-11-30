use core::starknet::ContractAddress;
use starknet::class_hash::ClassHash;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Organization {
    id: u256,
    name: felt252,
    region: felt252,
    validator:u256,
    domain:ContractAddress
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Listing {
    id: u256,
    details: ByteArray,
    hash:felt252,
    owner: ContractAddress,
}

#[starknet::interface]
pub trait IERC1155EXT<TContractState> {
     fn mint(
        ref self: TContractState,
        account: ContractAddress,
        token_id: u256,
        value: u256,
        data: Span<felt252>,
    );
}

#[starknet::interface]
pub trait IERC721EXT<TContractState> {
    fn safe_mint(
        ref self: TContractState,
        recipient: ContractAddress,
        token_id: u256,
        data: Span<felt252>,
    );
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> felt252;
    fn allowance(
        self: @TContractState, owner: ContractAddress, spender: ContractAddress
    ) -> felt252;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: felt252);
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: felt252
    );
}


#[starknet::interface]
pub trait IDao<TContractState> {
    fn register_validator(ref self: TContractState,validator:u256);
    fn create_listing(ref self: TContractState,details:ByteArray,hash:felt252) ;
    fn approve_listing(ref self: TContractState,_id:u256,hash:felt252);
    fn version(self: @TContractState) -> u16;
    fn get_unapproved_listings(self: @TContractState)-> Array<Listing>;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn hash(self: @TContractState, operand:felt252) -> felt252;
    fn get_erc20(self: @TContractState) -> ContractAddress;
    fn get_erc721(self: @TContractState) -> ContractAddress;
    fn get_erc1155(self: @TContractState) -> ContractAddress;
    fn get_listings(self: @TContractState) -> Array<Listing>;
    fn stake_listing_fee(ref self: TContractState);
    fn register_organization(ref self: TContractState,validator:u256, name: felt252,region:felt252);
    fn get_organizations(self: @TContractState) -> Array<Organization>;
    fn get_organization(self: @TContractState,domain:ContractAddress) -> Organization;
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
    fn set_erc1155(ref self: TContractState,address:ContractAddress);
    fn set_erc721(ref self: TContractState,address:ContractAddress);
    fn withdraw(ref self: TContractState,amount: u256);
    fn register_user(ref self: TContractState,details: ByteArray);
    fn get_user(self: @TContractState,address: ContractAddress) -> ByteArray;
    fn is_user_registered(self: @TContractState,address: ContractAddress) -> bool;
    fn has_staked(self: @TContractState,address:ContractAddress) -> bool;
   
}

#[starknet::contract]
mod dao {
    use super::{Organization,Listing, IERC1155EXTDispatcher,IERC1155EXTDispatcherTrait,IERC721EXTDispatcher,IERC721EXTDispatcherTrait,IERC20Dispatcher,IERC20DispatcherTrait};
    use starknet::{ContractAddress,get_caller_address,get_contract_address};
    use core::integer::u256;
    use core::num::traits::Zero;
    use  starknet::storage::Map;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::{poseidon::PoseidonTrait};
    use starknet::class_hash::ClassHash;
    use starknet::SyscallResultTrait;

    #[storage]
    struct Storage {
        owner:ContractAddress,
        erc20_address:ContractAddress,
        erc1155_address:ContractAddress,
        erc721_address:ContractAddress,
        organization_count: u256,
        users_count: u256,
        user_index: Map::<u256, ContractAddress>,
        user: Map::<ContractAddress, ByteArray>,
        registered: Map::<ContractAddress, bool>,
        organization_by_id: Map::<u256, Organization>,
        organization_by_domain: Map::<ContractAddress, Organization>,
        validators: Map::<u256, bool>,
        //listing
        has_staked:Map::<ContractAddress,bool>,
        listing_by_hash:Map::<felt252,bool>,
        listing_count:u256,
        unapproved_listing_count:u256,
        unapproved_listings: Map::<u256,Listing>,
        listings: Map::<u256,Listing>,
        version:u16,

    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Upgraded: Upgraded,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Upgraded {
        pub implementation: ClassHash
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner:ContractAddress,
        erc20_address:ContractAddress,
        erc1155_address:ContractAddress,
        erc721_address:ContractAddress
    ) {
        self.owner.write(owner);
        self.erc20_address.write(erc20_address);
        self.erc1155_address.write(erc1155_address);
        self.erc721_address.write(erc721_address);
      
    }


    #[abi(embed_v0)]
    impl DaoImpl of super::IDao<ContractState> {

         fn register_validator(ref self: ContractState,validator:u256) {
            assert(get_caller_address()==self.owner.read(),'UNAUTHORIZED');
            assert(!self.validators.read(validator),'DUPLICATE_VALIDATOR');
            self.validators.write(validator,true);
        }

        fn register_organization(ref self: ContractState,validator:u256, name: felt252,region:felt252) {
            assert(self.validators.read(validator),'INVALID_ORGANIZATION');
            let id = self.organization_count.read()+1;
            let new_org = Organization {id:id,name:name,region:region,validator:validator,domain:get_caller_address()};
            self.organization_by_id.write(id,new_org);
            self.organization_by_domain.write(get_caller_address(),new_org);
            self.organization_count.write(id);
            self.validators.write(validator,false);
            let erc1155_dispatcher = IERC1155EXTDispatcher{contract_address: self.erc1155_address.read()};
            erc1155_dispatcher.mint(get_caller_address(),1,1,[].span());
        }

        fn set_erc1155(ref self: ContractState,address:ContractAddress) {
          assert(get_caller_address()==self.owner.read(),'UNAUTHORIZED');
          assert(address.is_non_zero(), 'INVALID_ADDRESS');
          self.erc1155_address.write(address);
        }



        fn withdraw(ref self: ContractState,amount: u256) {
            assert(get_caller_address()==self.owner.read(),'UNAUTHORIZED');
            let erc20_dispatcher = IERC20Dispatcher{contract_address: self.erc20_address.read()};
            erc20_dispatcher.transfer(get_caller_address(),amount);
        }

        fn register_user(ref self: ContractState,details: ByteArray) {
            assert(!self.registered.read(get_caller_address()),'USER_ALREADY_EXIST');
            self.registered.write(get_caller_address(),true);
            self.user.write(get_caller_address(),details);
            let total_users = self.users_count.read();
            self.user_index.write(total_users+1,get_caller_address());
            self.users_count.write(total_users+1);
        }



        fn set_erc721(ref self: ContractState,address:ContractAddress) {
          assert(get_caller_address()==self.owner.read(),'UNAUTHORIZED');
          assert(address.is_non_zero(), 'INVALID_ADDRESS');
          self.erc721_address.write(address);
        }


        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            assert(impl_hash.is_non_zero(), 'Class hash cannot be zero');
            assert(get_caller_address()==self.owner.read(),'UNAUTHORIZED');
            starknet::syscalls::replace_class_syscall(impl_hash).unwrap_syscall();
            self.version.write(self.version.read()+1);
            self.emit(Event::Upgraded(Upgraded { implementation: impl_hash }))
        }

        fn version(self: @ContractState) -> u16 {
            self.version.read()
        }


        fn has_staked(self: @ContractState,address:ContractAddress) -> bool {
            self.has_staked.read(address)
        }

        fn get_organizations(self: @ContractState) -> Array<Organization> {
            let mut orgs:Array<Organization> = array![];
            let mut index = 1;
            while index<=self.organization_count.read() {
                orgs.append(self.organization_by_id.read(index));
                index+=1;
            };

            orgs
        }


        fn get_user(self: @ContractState,address: ContractAddress) -> ByteArray {
          self.user.read(address)
        }


        fn is_user_registered(self: @ContractState,address: ContractAddress) -> bool {
          self.registered.read(address)
        }


         fn hash(self: @ContractState, operand:felt252) -> felt252{
            let poseidon_hash = PoseidonTrait::new().update_with(operand).finalize();
            poseidon_hash
        }


        

        fn get_organization(self: @ContractState,domain:ContractAddress) -> Organization {
           self.organization_by_domain.read(domain)
        }

           fn get_owner(self: @ContractState) -> ContractAddress {
           self.owner.read()
        }

             fn get_erc20(self: @ContractState) -> ContractAddress {
           self.erc20_address.read()
        }

             fn get_erc721(self: @ContractState) -> ContractAddress {
           self.erc721_address.read()
        }

             fn get_erc1155(self: @ContractState) -> ContractAddress {
           self.erc1155_address.read()
        }

        // Listing

         fn create_listing(ref self: ContractState,details:ByteArray,hash:felt252) {
            assert(self.has_staked.read(get_caller_address()),'NOT_STAKED');
            assert(!self.listing_by_hash.read(hash),'LISTING_ALREADY_EXIST');
            let id = self.unapproved_listing_count.read()+1;
            let listing = Listing{id,owner:get_caller_address(),details,hash};
            self.listing_by_hash.write(hash,true);
            self.unapproved_listings.write(id,listing);
            self.unapproved_listing_count.write(id);
            self.has_staked.write(get_caller_address(), false);
        }


        fn approve_listing(ref self: ContractState,_id:u256,hash:felt252) {
            assert(self.organization_by_domain.read(get_caller_address()).domain.is_non_zero(),'UNAUTHORIZED');
            assert(self.listing_by_hash.read(hash),'LISTING_DOES_NOT_EXIST');
            let listing = self.unapproved_listings.read(_id);
            assert(listing.hash == hash,'INVALID_LISTING');
            assert(listing.owner.is_non_zero() && listing.id!=0,'INVALID_LISTING');
            let id = self.listing_count.read()+1;
            self.listing_count.write(id);

            let erc20_dispatcher = IERC20Dispatcher{contract_address: self.erc20_address.read()};
            let erc721_dispatcher = IERC721EXTDispatcher{contract_address: self.erc721_address.read()};
            let agent_fee = 10_000_000_000_000_000_000;
            erc20_dispatcher.transfer(get_caller_address(),agent_fee.into());
            erc721_dispatcher.safe_mint(listing.owner,id,[].span());
            self.listings.write(id,listing);

            self.unapproved_listings.write(_id,Listing{hash:'',id:0,owner:Zero::zero(),details:""});
            
        }


        fn stake_listing_fee(ref self: ContractState) {
            let staking_fee:felt252 = 20_000_000_000_000_000_000;
            let erc20_dispatcher = IERC20Dispatcher{contract_address: self.erc20_address.read()};
            let allowance:u256 = erc20_dispatcher.allowance(get_caller_address(),get_contract_address()).into();
            assert(allowance>= staking_fee.into(),'NO_ALLOWANCE');
            erc20_dispatcher.transfer_from(get_caller_address(),get_contract_address(),staking_fee.into());
            self.has_staked.write(get_caller_address(), true);
          
        }


        fn get_unapproved_listings(self: @ContractState) -> Array<Listing> {
            let mut listings:Array<Listing> = array![];
            let mut index = 1;
            while index<=self.unapproved_listing_count.read() {
                let listing = self.unapproved_listings.read(index);
                if listing.owner != Zero::zero(){
                    listings.append(self.unapproved_listings.read(index));
                }
                index+=1;
            };

            listings
        }

        fn get_listings(self: @ContractState) -> Array<Listing> {
            let mut listings:Array<Listing> = array![];
            let mut index = 1;
            while index<=self.listing_count.read() {
                listings.append(self.listings.read(index));
                index+=1;
            };

            listings
        }
    }
}
