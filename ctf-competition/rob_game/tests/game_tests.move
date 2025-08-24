#[test_only]
module game::game_tests {
    use sui::test_scenario::{Self as ts};
    use sui::random::{Random};
    use sui::object;
    use sui::transfer;
    use std::vector;
    use std::debug::{print};

    use game::ez_game::{Challenge, init_game, get_flag, weighted_rob};

    const ENotImplemented: u64 = 0;

    // #[test]
    // fun test_game() {
    //     let sender = @0xcafe;
    //     let mut s = ts::begin(sender);

    //     // 1. initial game
    //     s.next_tx(sender);
    //     let random: Random = s.take_shared<Random>();
    //     init_game(&random, s.ctx());
    //     // 1 1 3 1 1
    //     // 1 1 2 1 1
    //     // 2. construct a input and pass into get_flag()
    //     s.next_tx(sender);
    //     let mut challenge: Challenge = s.take_shared<Challenge>();
    //     let target_amount: u64 = challenge.target_amount;
    //     let user_input: vector<u64> = vector[1];
    //     get_flag(user_input, &mut challenge, s.ctx());

    //     ts::return_shared(random);
    //     ts::return_shared(challenge);
    //     s.end();
    // }

    #[test, expected_failure(abort_code = ::game::game_tests::ENotImplemented)]
    fun test_game_fail() {
        abort ENotImplemented
    }
}

