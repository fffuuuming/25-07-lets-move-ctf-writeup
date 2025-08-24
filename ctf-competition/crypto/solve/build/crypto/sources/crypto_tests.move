
#[test_only]
module crypto::crypto_tests;

use sui::random::{Self, Random, new_generator};
use std::debug::print;
use sui::test_scenario;
use crypto::crypto;

#[test]
public fun test() {
    let flag = b"flag{5Ui_M0Ve_CONtrAC7}";
    let dev = @0x0;
    let mut scenario_val = test_scenario::begin(dev);
    let scenario = &mut scenario_val;
    scenario.next_tx(dev);
    {
        random::create_for_testing(scenario.ctx());
    };
    scenario.next_tx(dev);
    {
        let r = scenario.take_shared<Random>();
        crypto::entrypt_flag(flag, &r, scenario.ctx());
        test_scenario::return_shared(r);
        
        crypto::decrypt_flag(flag, &mut sui::tx_context::dummy());
    };
    scenario_val.end();
}