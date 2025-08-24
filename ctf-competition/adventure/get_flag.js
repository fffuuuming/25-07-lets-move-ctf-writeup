import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';


const secretKey = 'suiprivkey1qqsqnl67wmxvme3sv34endnujtr8yp0638vekzt9k5ael07qnrgdu52dr9g';
const keypair = Ed25519Keypair.fromSecretKey(secretKey);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();
const suiRpcUrl = 'https://fullnode.testnet.sui.io/';

const client = new SuiClient({ url: getFullnodeUrl('testnet') });

const PACKAGE_ID = '0xa1f5bf15c4749f9d97f8d4727bb6013389d830613f0f135fe8958d8f43f3a1f7'; // PACKAGE_ID
const digest = 'E85jqE9zxpMJhGmhVq8gLZUgxxTykizfaDnCw9kxdRwr';

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

async function get_transaction_events(digest) {
    try {
        const response = await axios.post(suiRpcUrl, {
            jsonrpc: '2.0',
            id: 1,
            method: 'sui_getTransactionBlock',
            params: [
                digest, 
                {showInput: false,showRawInput: false,showEffects: false,showEvents: true, showObjectChanges: false,showBalanceChanges: false}
            ]
        }, {
            headers: {
                'Content-Type': 'application/json'
            }
        });
        const events = response.data.result?.events;
        if (events && events.length > 0) {
            console.log('交易触发的事件列表:');
            let amount = null;
            for (const event of events){
                if (event.parsedJson && 'amount' in event.parsedJson) {
                    amount = parseInt(event.parsedJson.amount, 10); 
                    console.log('Amount:', amount);
                    break;
                }else{
                    console.log('事件内容:', event.parsedJson);
                }
            }
            return amount;
        } else {
            console.log('该交易没有触发任何事件。');
            return 0;
        }

    } catch (error) {
        console.error('获取交易事件失败:', error.message);
        return 0;
    }
}


let newobjectId = await get_newly_created_object(digest);
if (newobjectId != null){
    // get flag
    const tx5 = new Transaction();
    tx5.moveCall({
        target: `${PACKAGE_ID}::inventory::get_flag`,
        arguments: [tx5.object(newobjectId),]
    });
    const result5 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx5,});
    console.log('Transaction Result:', result5);

    await get_transaction_events(result5.digest);
}