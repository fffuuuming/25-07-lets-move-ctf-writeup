module liquidity::challenge;

use sui::coin::{Self, Coin};
use sui::balance::Balance;
use sui::event;

use liquidity::pool::{Self, CreatePoolCap, Pool};
use liquidity::ctfa::{Self, CTFA, MintCTFA};
use liquidity::ctfb::{Self, CTFB, MintCTFB};
use liquidity::lp::LP;

const EAlreadyClaimed: u64 = 0;
const ENotSolved: u64 = 1;
const EAlreadySolved: u64 = 2;

public struct FlagEvent has copy, drop {
    owner: address,
    flag: bool
}

public struct Challenge<phantom LP, phantom CTFA, phantom CTFB> has key, store {
    id: UID,
    pool: Pool<LP>,
    airdrop_balance: Balance<CTFB>,
    claimed: bool,
    success: bool,
}

public fun get_pool(challenge: &Challenge<LP, CTFA, CTFB>): &Pool<LP> {
    &challenge.pool
}

public fun get_pool_mut(challenge: &mut Challenge<LP, CTFA, CTFB>): &mut Pool<LP> {
    &mut challenge.pool
}

public fun create_challenge(mint_CTFA: MintCTFA<CTFA>, mint_CTFB: MintCTFB<CTFB>, create_cap: CreatePoolCap<LP>, ctx: &mut TxContext): Challenge<LP, CTFA, CTFB> {
    assert!(mint_CTFA.get_total_supply() == 0);
    assert!(mint_CTFB.get_total_supply() == 0);
    
    let coin_1 = ctfa::mint_for_pool<CTFA>(mint_CTFA, ctx);
    let mut coin_2 = ctfb::mint_for_pool<CTFB>(mint_CTFB, ctx);
    
    let pool = pool::new(create_cap, coin_1, coin_2.split(10000000, ctx), 1000, vector[6,6], ctx);

    let challenge = Challenge<LP, CTFA, CTFB> {
        id: object::new(ctx),
        pool: pool,
        airdrop_balance: coin::into_balance(coin_2),
        claimed: false,
        success: false,
    };
    challenge
}

public fun claim_airdrop(challenge: &mut Challenge<LP, CTFA, CTFB>, ctx: &mut TxContext): Coin<CTFB> {
    assert!(!challenge.claimed, EAlreadyClaimed);

    challenge.claimed = true;
    let airdrop = challenge.airdrop_balance.withdraw_all().into_coin(ctx);

    airdrop
}

public fun is_solved(challenge: &Challenge<LP, CTFA, CTFB>): bool {
    let pool = &challenge.pool;
    let ctfa_balance = pool.balance_of<LP, CTFA>();
    let is_flashloan = pool.is_flashloan();

    ctfa_balance == 0 && is_flashloan == false
}

public fun get_flag(challenge: &mut Challenge<LP, CTFA, CTFB>, ctx: &mut TxContext) {
    assert!(is_solved(challenge), ENotSolved);
    assert!(!challenge.success, EAlreadySolved);

    challenge.success = true;

    event::emit(FlagEvent {
        owner: ctx.sender(),
        flag: true
    });
}