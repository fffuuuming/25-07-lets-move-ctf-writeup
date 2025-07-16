// PackageID: 0x65fb06b4e31f157388ef08831ee18266de8d5decfedd225cba04efc809ed17f4
module solve_week4::exploit_helper {
    use sui::clock;

    entry fun check_timestamp(clock: &clock::Clock){
        let current_timestamp = clock::timestamp_ms(clock);
        let d100 = current_timestamp % 3;
        assert!(d100 == 1);
    }
}

