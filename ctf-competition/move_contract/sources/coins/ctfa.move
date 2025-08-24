module liquidity::ctfa;

use sui::coin::{Self, TreasuryCap, Coin};

public struct CTFA has drop {}

public struct MintCTFA<phantom CTFA> has key, store {
    id: UID,
    cap: TreasuryCap<CTFA>
}

fun init(witness: CTFA, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
        witness,
        6,
        b"CTFA",
        b"CTFA",
        b"CTFA Coin",
        option::none(),
        ctx,
    );
    let mint = MintCTFA<CTFA> {
        id: object::new(ctx),
        cap: treasury
    };
    transfer::share_object(mint);
    transfer::public_freeze_object(metadata);
}

public fun get_total_supply(mint: &MintCTFA<CTFA>): u64 {
    mint.cap.total_supply()
}

public(package) fun mint_for_pool<CTFA>(mut mint: MintCTFA<CTFA>, ctx: &mut TxContext): Coin<CTFA> {
    let coin_CTFA = mint.cap.mint(10000000, ctx);
    let MintCTFA<CTFA> {
        id: idb,
        cap: treasury
    } = mint;
    object::delete(idb);
    transfer::public_freeze_object(treasury);
    coin_CTFA
}

#[test_only]
public fun share_for_testing(witness: CTFA, ctx: &mut TxContext) {
    init(witness, ctx);
}