module my_addr::UserManagement {

    use std::signer;
    use std::vector;
    use std::error;
    use std::event;
    
     // Define an error category for the module
    const EUSER_ALREADY_REGISTERED: u64 = 0;
    const EUSER_NOT_REGISTERED: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;

    // Event to emit when a user is registered
    #[event]
    struct UserRegisteredEvent has copy, drop,store  {
        user: address,
    }

    struct UserBalanceUpdatedEvent has copy, drop, store {
        user:address,
        balance: u64,
    }

    // Resource to hold user information
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct User has key {
        balance: u64,
        transaction_history: vector<u64>,
    }

    /* // Initialize the module (if needed)
    private entry fun init_module(account: &signer) {
        // Module initialization logic, if any
    } */

    public entry fun register_user(account: &signer){
        let user_address = signer::address_of(account);

        if (exists<User>(user_address)) {
            // User already exists, emit an error
            abort error::invalid_argument(EUSER_ALREADY_REGISTERED)
        };

        let user  = User {
            balance: 0,
            transaction_history: vector::empty(),
        };

        move_to<User>(account, user);
        
        event::emit(UserRegisteredEvent { user: user_address });
        

    }

    public entry fun deposit(account: &signer, amount: u64) acquires User {
        let user_address = signer::address_of(account);
        assert!(exists<User>(user_address), error::not_found(EUSER_NOT_REGISTERED));
        let user = borrow_global_mut<User>(user_address);
        user.balance = user.balance + amount;
    }
}