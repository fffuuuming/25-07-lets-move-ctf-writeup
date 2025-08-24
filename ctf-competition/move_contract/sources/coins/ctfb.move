module liquidity::ctfb;

use sui::coin::{Self, TreasuryCap, Coin};

public struct CTFB has drop {}

public struct MintCTFB<phantom CTFB> has key, store {
    id: UID,
    cap: TreasuryCap<CTFB>
}

fun init(witness: CTFB, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
        witness,
        6,
        b"CTFB",
        b"CTFB",
        b"CTFB Coin",
        option::none(),
        ctx,
    );
    let mint = MintCTFB<CTFB> {
        id: object::new(ctx),
        cap: treasury
    };
    transfer::share_object(mint);
    transfer::public_freeze_object(metadata);
}

public fun get_total_supply(mint: &MintCTFB<CTFB>): u64 {
    mint.cap.total_supply()
}

public(package) fun mint_for_pool<CTFB>(mut mint: MintCTFB<CTFB>, ctx: &mut TxContext): Coin<CTFB> {
    let coin_CTFB = mint.cap.mint(20000000, ctx);
    let MintCTFB<CTFB> {
        id: idb,
        cap: treasury
    } = mint;
    object::delete(idb);
    transfer::public_freeze_object(treasury);
    coin_CTFB
}

#[test_only]
public fun share_for_testing(witness: CTFB, ctx: &mut TxContext) {
    init(witness, ctx);
}