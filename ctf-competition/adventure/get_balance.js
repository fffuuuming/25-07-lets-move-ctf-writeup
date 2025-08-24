import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';


const secretKey = 'suiprivkey1qqsqnl67wmxvme3sv34endnujtr8yp0638vekzt9k5ael07qnrgdu52dr9g';
const keypair = Ed25519Keypair.fromSecretKey(secretKey);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl('testnet') });

const userTokenAmountId = '0x6b1ff9e6dcc6486644422356cb04466227799f6799a6fbfc4a031ec4cdfe32aa';// userTokenAmountId

async function get_balance() {
    // Step 1: Get balances table ID
    const object = await client.getObject({
        id: userTokenAmountId,
        options: { showContent: true }
    });

    const balancesTableId = object.data?.content?.fields?.balances?.fields?.id?.id;

    if (!balancesTableId) {
        console.error('Failed to extract balances Table ID');
        return;
    }

    // Step 2: Get dynamic field for this address
    const dynamicField = await client.getDynamicFieldObject({
        parentId: balancesTableId,
        name: {
            type: 'address',
            value: address
        }
    });

    const balance = dynamicField.data?.content?.fields?.value;
    console.log(`✅ Balance for ${address}:`, balance);

    return balance;
}

const balance = await get_balance();
console.log("sender balance:", balance);