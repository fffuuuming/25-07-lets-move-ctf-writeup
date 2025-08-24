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
const PACKAGE_ID = '0x5941e09a9b232cc7c1185a9d5b9d46539663473d8a2d525b5f42d89d111fde7f'; // PACKAGE_ID

const tx4 = new Transaction();
tx4.moveCall({
    target: `${PACKAGE_ID}::adventure::buy_box`,
    arguments: [tx4.object(userTokenAmountId),]
});
const result4 = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx4,
    requestType: 'WaitForEffectsCert',
    options: {
        showEffects: true,
        showObjectChanges: true,
    }
});
console.log('Transaction Result:', result4);