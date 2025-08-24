import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';


const secretKey = 'suiprivkey1qqsqnl67wmxvme3sv34endnujtr8yp0638vekzt9k5ael07qnrgdu52dr9g';
const keypair = Ed25519Keypair.fromSecretKey(secretKey);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl('testnet') });

const poolsId = '0xe85984a7a8aac6060cf3084f33ef3ff090e2305253253cf320a8d2638f69a3ab';// userTokenAmountId

async function get_balance() {
    // Step 1: Get balances table ID
    const object = await client.getObject({
        id: poolsId,
        options: { showContent: true }
    });
    
    const fields = object.data?.content?.fields;
    const bagId = fields.balance_bag.fields.id.id;
    // console.log(object);
    console.log(fields);
    console.log(bagId);

    const dynamicFields = await client.getDynamicFields({ parentId: bagId });
    console.log(dynamicFields);

    for (let i = 0; i < dynamicFields.data.length; i++) {
        const tokenId = dynamicFields.data[i].objectId;
        const token_balance = await client.getObject({
            id: tokenId,
            options: { showContent: true }
        })
        console.log("token balance:", token_balance.data.content.fields.value);
    }
    // const token1Id = dynamicFields.data[0].objectId;
    // const token1_balance = await client.getObject({
    //     id: token1Id,
    //     options: { showContent: true }
    // })
    // console.log("token1 balance:", token1_balance.data.content.fields.value);

    return fields
}

await get_balance();
