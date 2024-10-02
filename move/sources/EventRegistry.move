module my_addr::EventRegistry {
    use std::signer;
    use std::error;
    use std::event;
    use std::table;
    use std::option;
    use std::vector;

    //ERRORS

    const EEVENT_ALREADY_EXISTS: u64 = 0;
    const EEVENT_NOT_FOUND: u64 = 1;
    const EUNAUTHORIZED: u64 = 2;
    const EEVENT_CLOSED: u64 = 3;
    const EEVENT_NOT_RESOLVED: u64 = 4;
    const EOUTCOME_NOT_FOUND: u64 = 5;
    const EOUTCOME_ALREADY_EXISTS: u64 = 6;

    //EVENT STATUSES

    const EVENT_STATUS_OPEN: u8 = 0;
    const EVENT_STATUS_CLOSED: u8 = 1;
    const EVENT_STATUS_RESOLVED: u8 = 2;

    
    struct Event has copy, drop, key,store {
        event_id: u64,
        name: vector<u8>,
        date: u64, // Timestamp
        status: u8,
        outcomes: vector<vector<u8>>, // List of possible outcomes
        resolution_outcome: option::Option<vector<u8>>,
        
    }
    

    // Define the OutcomeToken struct
    struct OutcomeToken has store, key {
        // Unique identifier for the token type
        token_type: u64,
        // The market ID this token is associated with
        event_id: u64,
        // The outcome this token represents
        outcome: vector<u8>,
        // Total supply of this token
        total_supply: u64,
    }

     // Resource to store all OutcomeTokens
     #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct OutcomeTokenRegistry has key {
        tokens: table::Table<u64, OutcomeToken>,
    }


    // Resource to hold a user's balance of OutcomeTokens
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct UserOutcomeTokens has key {
        holdings: table::Table<u64, u64>, // token_type => amount
    }


    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Events has key {
        events: table::Table<u64, Event>,
    }

    #[event]
    struct EventCreatedEvent has copy, drop, store {
        event_id: u64,
        name: vector<u8>,
        date: u64,
    }

    // Initialize the Events resource
    fun init_events(account: &signer) {
        move_to<Events>(account, Events { events: table::new() });
    }

    // Initialize the OutcomeTokenRegistry resource
    fun init_token_registry(account: &signer) {
        move_to<OutcomeTokenRegistry>(account, OutcomeTokenRegistry { tokens: table::new() });
    }

    // Initialize the OutcomeToken resource for a user
    fun init_user_tokens(account: &signer) {
        move_to<UserOutcomeTokens>(account, UserOutcomeTokens { holdings: table::new() });
    }

    /// Initializes the EventRegistry module by setting up necessary resources
    fun init_module(
        account: &signer
    ) {
        init_events(account);
        init_token_registry(account);
        init_user_tokens(account);
    }

     /// Stores an OutcomeToken in the OutcomeTokenRegistry
    fun store_outcome_token(registry_address: address, token: OutcomeToken)acquires OutcomeTokenRegistry{
        let registry = borrow_global_mut<OutcomeTokenRegistry>(registry_address);

        if (table::contains(&registry.tokens, token.token_type)) {
            abort error::invalid_argument(EOUTCOME_ALREADY_EXISTS)
        };

        table::add(&mut registry.tokens, token.token_type, token);
    }

    /// Generates a unique token type ID based on event ID and outcome index
    fun generate_token_type(event_id: u64, outcome_index: u64): u64 {
        // TODO
        event_id * 1000 + outcome_index
    }


    public entry fun add_event(account:&signer, name:vector<u8>,  event_id: u64, date: u64, outcomes: vector<vector<u8>>) acquires Events, OutcomeTokenRegistry {

        assert!(is_authorized(account), error::permission_denied(EUNAUTHORIZED));
        let events = borrow_global_mut<Events>(@my_addr);//TODO
        if (table::contains(&events.events, event_id)) {
            abort error::invalid_argument(EEVENT_ALREADY_EXISTS)
        };
        let event = Event {
            event_id,
            name,
            date,
            status: 0,
            outcomes: outcomes,
            resolution_outcome: option::none<vector<u8>>(),
        };
        // add event to table
        table::add(&mut events.events, event_id, event);
       // Initialize OutcomeTokens for this event
        let registry_address = @my_addr;

        for (i in 0..vector::length(&outcomes)){
            let outcome = vector::borrow(&outcomes, i);
            let token_type = generate_token_type(event_id, i as u64);

            let outcome_token = OutcomeToken {
                token_type,
                event_id,
                outcome:*outcome,
                total_supply: 0,
            };

            // Store the OutcomeToken in the registry
            store_outcome_token(registry_address, outcome_token);
        };
        event::emit(EventCreatedEvent { event_id, name, date });
        

    }

     public fun get_event(event_id: u64): Event acquires Events {
        let events = borrow_global<Events>(@my_addr);
        if (!table::contains(&events.events, event_id)) {
            abort error::not_found(EEVENT_NOT_FOUND)
        };
        let event = table::borrow(&events.events, event_id);
        *event
    }

    fun is_authorized(account: &signer): bool {
        true // Placeholder
    }

     


}