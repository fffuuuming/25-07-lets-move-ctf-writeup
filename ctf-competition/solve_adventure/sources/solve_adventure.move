// PackageID: 0x626de4e6d4c2648304567c34d28b31dd60493bcccdc58dd933a2907de789bdab
module solve_adventure::exploit_helper {
    use sui::clock;

    entry fun check_timestamp(clock: &clock::Clock){
        let current_timestamp = clock::timestamp_ms(clock);
        let d100 = current_timestamp % 3;
        assert!(d100 == 1);
    }
}
