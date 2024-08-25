use core::starknet::ContractAddress;

#[Drop]
struct Organization {
    id: u256,
    name: String,
    region: String,
    validator:u256,
    domain:ContractAddress
}
#[starknet::interface]
pub trait IDao<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod Dao {
    use core::starknet::ContractAddress;
      use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess, Map
    };
    #[storage]
    struct Storage {
        owner:ContractAddress,
        organization_count: u256, 
        organization: Map::<u256, Organization>,
        validators: Map<u256, bool>
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner:ContractAddress
    ) {
        self.owner.write(get_caller_address());
    }


    #[abi(embed_v0)]
    impl DaoImpl of super::IDao<ContractState> {

         fn register_validator(ref self: ContractState,validator:u256) {
            assert!( get_caller_address()==self.owner.read(),"UNAUTHORIZED");
            self.validators.write(validator,true);
        }

        fn register_organization(ref self: ContractState,validator:u256, name: String,region:String) {
            assert!(self.validators.read(validator),"INVALID_ORGANIZATION");
            let id = self.organization_count+1;
            let new_org = Organization {id:id,name:name,region:region,validator:validator,domain:get_caller_address()};
            self.organization.write(id,new_org);
            self.organization_count.write(id);
            self.validators.write(validator,false);
        }

        fn get_organizations(self: @ContractState) -> Array<Organization> {
            let orgs:Array<Organization> = array![];
            let index = 1;
            while <=self.organization_count.read() {
                orgs.append(self.organization.read(index));
                index+=1;
            }

            orgs
        }

        fn get_organization(self: @ContractState,id:u256) -> Organization {
           self.organization.read(id)
        }




        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}
