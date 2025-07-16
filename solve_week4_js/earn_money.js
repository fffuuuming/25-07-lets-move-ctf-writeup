import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';

const MNEMONIC = '';// 自己的助记词
const keypair = Ed25519Keypair.deriveKeypair(MNEMONIC);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();
console.log('Wallet Address:', address);
const client = new SuiClient({ url: getFullnodeUrl('devnet') });
let balance = await client.getBalance({ owner: address });
console.log('Account Balance:', balance);
const heroId = '';// heroId
const userTokenAmountId = '';// userTokenAmountId
const PACKAGE_ID = ''; // PACKAGE_ID
const suiRpcUrl = 'https://fullnode.devnet.sui.io/';


async function get_newly_created_object(digest) {
    try {
        const response = await axios.post(suiRpcUrl, {
            jsonrpc: '2.0',
            id: 1,
            method: 'sui_getTransactionBlock',
            params: [
                digest,
                {
                    showEffects: true,
                    showObjectChanges: true
                }
            ]
        }, {
            headers: { 'Content-Type': 'application/json' }
        });
        const result = response.data.result;
        const createdObjects = result.effects?.created || [];
        if (createdObjects.length === 0) {
            console.log('未找到新创建的对象');
            return null;
        }

        const newObjectId = createdObjects[0].reference.objectId;
        console.log('新对象 ID:', newObjectId);
        return newObjectId;

    } catch (error) {
        console.error('获取新对象失败:', error.message);
        return null;
    }
}

const tx = new Transaction();

// Initialize & get the Vault
tx1.moveCall({
    target: `${PACKAGE_ID}::vault::init_vault`,
});
const tx1 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx1,}); 
let vault = await get_newly_created_object(tx1.digest);

// Buy, cook and sell potatoes until balance >= 200
while (true) {
  try {
    const tx = new TransactionBlock();
    const num = 2047;
    tx.moveCall({
      target: `${PACKAGE_ID}::potato::new_obj`, // dummy object creator, you write it
      arguments: [tx.pure.u64(num), tx.pure.address(address)],
    });
    const potato = tx.moveCall({
      target: `${PACKAGE_ID}::potato::buy_potato`,
      arguments: [tx.object(vaultId)],
    });
    const potatoMut = tx.borrowMut(potato);
    tx.moveCall({
      target: `${PACKAGE_ID}::potato::cook_potato`,
      arguments: [tx.object(vaultId), potatoMut],
    });
    tx.moveCall({
      target: `${PACKAGE_ID}::potato::sell_potato`,
      arguments: [tx.object(clockId), tx.object(vaultId), potato, tx.object(ctx)],
    });

    const result = await client.signAndExecuteTransaction({ signer, transaction: tx });
    const newBalance = await get_transaction_events(result.digest);
    if (newBalance >= target) break;
  } catch (e) {
    console.error('Error');
    continue;
  }
}



