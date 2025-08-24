module solve_swap::token1 {
    use sui::coin;
    public struct TOKEN1 has drop {}

    fun init(witness: TOKEN1, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token1", b"", b"", option::none(), ctx);
        coin::mint_and_transfer(&mut treasury_cap, 8000, tx_context::sender(ctx), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TOKEN1 {}, ctx); 
    }
}

module solve_swap::token2 {
    use sui::coin;
    public struct TOKEN2 has drop {}

    fun init(witness: TOKEN2, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token2", b"", b"", option::none(), ctx);
        coin::mint_and_transfer(&mut treasury_cap, 8000, tx_context::sender(ctx), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TOKEN2 {}, ctx); 
    }
}

module solve_swap::token3 {
    use sui::coin;
    public struct TOKEN3 has drop {}

    fun init(witness: TOKEN3, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token3", b"", b"", option::none(), ctx);
        coin::mint_and_transfer(&mut treasury_cap, 8000, tx_context::sender(ctx), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TOKEN3 {}, ctx); 
    }
}

module solve_swap::token4 {
    use sui::coin;
    public struct TOKEN4 has drop {}

    fun init(witness: TOKEN4, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token4", b"", b"", option::none(), ctx);
        coin::mint_and_transfer(&mut treasury_cap, 8000, tx_context::sender(ctx), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TOKEN4 {}, ctx); 
    }
}


