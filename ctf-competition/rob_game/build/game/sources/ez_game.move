module game::ez_game {
    use sui::math;
    use sui::event;
    use sui::random::{Self, Random};

    public struct Challenge has key, store {
        id: UID,
        initial_part: vector<u64>,
        weights: vector<u64>,
        target_amount: u64,
    }

    public struct Flag has copy, drop {
        owner: address,
        flag: bool
    }

    entry fun init_game(random: &Random,ctx: &mut TxContext) {
        let mut gen = random::new_generator(random, ctx);
        let num = random::generate_u64_in_range(&mut gen, 10, 20);
        let mut initial_part = vector::empty<u64>();
        vector::push_back(&mut initial_part, 1);
        vector::push_back(&mut initial_part, 1);
        vector::push_back(&mut initial_part, 3);
        vector::push_back(&mut initial_part, 1);
        vector::push_back(&mut initial_part, 1);

        let mut weights = vector::empty<u64>();
        vector::push_back(&mut weights, 1);
        vector::push_back(&mut weights, 1);
        vector::push_back(&mut weights, 2);
        vector::push_back(&mut weights, 1);
        vector::push_back(&mut weights, 1);

        let challenge = Challenge {
            id: object::new(ctx),
            initial_part: initial_part,
            weights: weights,
            target_amount: num,
        };
        transfer::share_object(challenge);
    }

    public entry fun get_flag(user_input: vector<u64>, rc: &mut Challenge, ctx: &mut TxContext) {
        let sender = sui::tx_context::sender(ctx);
        let mut houses = rc.initial_part;
        let mut weights = rc.weights;
        vector::append(&mut houses, user_input);
        let mut i = vector::length(&rc.initial_part);
        while (i < vector::length(&houses)) {
            vector::push_back(&mut weights, 1);
            i = i + 1;
        };
        let amount_robbed = weighted_rob(&houses, &weights);
        let result = amount_robbed == rc.target_amount;
        if (result) {
            event::emit(Flag { owner: sender, flag: true });
        };
    }

    #[allow(deprecated_usage)]
    fun weighted_rob(houses: &vector<u64>, weights: &vector<u64>): u64 {
        let n = vector::length(houses);
        assert!(n == vector::length(weights), 0);
        if (n == 0) {
            return 0
        };
        let mut v = vector::empty<u64>();
        vector::push_back(&mut v, *vector::borrow(houses, 0) * *vector::borrow(weights, 0));
        if (n > 1) {
            vector::push_back(&mut v, math::max(
                *vector::borrow(houses, 0) * *vector::borrow(weights, 0),
                *vector::borrow(houses, 1) * *vector::borrow(weights, 1)
            ));
        };
        let mut i = 2;
        while (i < n) {
            let dp_i_1 = *vector::borrow(&v, i - 1);
            let dp_i_2_plus_house = *vector::borrow(&v, i - 2) + *vector::borrow(houses, i) * *vector::borrow(weights, i);
            vector::push_back(&mut v, math::max(dp_i_1, dp_i_2_plus_house));
            i = i + 1;
        };
        *vector::borrow(&v, n - 1)
    }
}