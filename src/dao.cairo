use core::starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
 pub struct Organization {
    id: u256,
    name: felt252,
    region: felt252,
    validator:u256,
    domain:ContractAddress
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
pub trait IDao<TContractState> {
    fn register_validator(ref self: TContractState,validator:u256);
    fn register_organization(ref self: TContractState,validator:u256, name: felt252,region:felt252);
    fn get_organizations(self: @TContractState) -> Array<Organization>;
    fn get_organization(self: @TContractState,domain:ContractAddress) -> Organization;
   
}

#[starknet::contract]
mod dao {
    use super::{Organization,IERC1155EXTDispatcher,IERC1155EXTDispatcherTrait};
    use core::starknet::{ContractAddress,get_caller_address};
    use core::integer::u256;
  use  starknet::storage::Map;

   // use openzeppelin::token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
    #[storage]
    struct Storage {
        owner:ContractAddress,
        erc20_address:ContractAddress,
        erc1155_address:ContractAddress,
        organization_count: u256,
        organization_by_id: Map::<u256, Organization>,
        organization_by_domain: Map::<ContractAddress, Organization>,
        validators: Map::<u256, bool>
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner:ContractAddress,
        erc20_address:ContractAddress,
        erc1155_address:ContractAddress
    ) {
        self.owner.write(get_caller_address());
        self.erc20_address.write(erc20_address);
        self.erc1155_address.write(erc1155_address);
    }


    #[abi(embed_v0)]
    impl DaoImpl of super::IDao<ContractState> {

         fn register_validator(ref self: ContractState,validator:u256) {
            assert!( get_caller_address()==self.owner.read(),"UNAUTHORIZED");
            self.validators.write(validator,true);
        }

        fn register_organization(ref self: ContractState,validator:u256, name: felt252,region:felt252) {
            assert!(self.validators.read(validator),"INVALID_ORGANIZATION");
            let id = self.organization_count.read()+1;
            let new_org = Organization {id:id,name:name,region:region,validator:validator,domain:get_caller_address()};
            self.organization_by_id.write(id,new_org);
            self.organization_by_domain.write(get_caller_address(),new_org);
            self.organization_count.write(id);
            self.validators.write(validator,false);
            let erc1155_dispatcher = IERC1155EXTDispatcher{contract_address: self.erc1155_address.read()};
            erc1155_dispatcher.mint(get_caller_address(),1,1,[].span());
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

        fn get_organization(self: @ContractState,domain:ContractAddress) -> Organization {
           self.organization_by_domain.read(domain)
        }

    }
}
