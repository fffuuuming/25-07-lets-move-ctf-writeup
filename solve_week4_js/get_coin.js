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

async function get_experience() {
    try {
        const response = await axios.post(suiRpcUrl,{jsonrpc: '2.0',id: 1, method: 'sui_getObject',params: [heroId,{showType: true,showOwner: true,showDepth: true,showContent: true,showDisplay: true,},],},{headers: {'Content-Type': 'application/json',},});
        const fields = response.data.result?.data?.content?.fields;
        if (fields) {console.log('Experience:', fields.experience);console.log('Level', fields.level)} else {console.log('No fields found in the object.');}
        return fields.experience 
    } catch (error) {
        console.error('Error fetching object data:', error.message);
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
// 升级英雄
let i = 0;
while(i<200){
    const tx = new Transaction();
    tx.moveCall({
        target: `${PACKAGE_ID}::adventure::slay_boar`,
        arguments: [
            tx.object(heroId),
            ]
        });
    let experience = await get_experience();
    console.log("experience: ",experience);
    if (experience >= 100){
        tx.moveCall({
            target: `${PACKAGE_ID}::hero::level_up`,
            arguments: [tx.object(heroId),]
        });
        const result = await client.signAndExecuteTransaction({signer: keypair,transaction: tx,});
        console.log('Transaction Result:', result);
        break;
    }
    const result = await client.signAndExecuteTransaction({signer: keypair,transaction: tx,});
    console.log('Transaction Result:', result);
}
// 初始化balances
const tx1 = new Transaction();
tx1.moveCall({
            target: `${PACKAGE_ID}::adventure::init_balances`,
            arguments: [tx1.object(userTokenAmountId),]
        });
const result1 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx1,});
console.log('Transaction Result:', result1);
// 打野猪王获取balances
while(true){
      try{
        const tx3 = new Transaction();
        let num = 2047;
        const address1 = ''// 随便写一个地址
        tx3.moveCall({
                target: `${PACKAGE_ID}::adventure::new_obj`,
                arguments: [tx3.pure.u64(num), tx3.pure.address(address1),]
            });
        tx3.moveCall({
                target: `${PACKAGE_ID}::adventure::slay_boar_king`,
                arguments: [tx3.object('0x6'), tx3.object(userTokenAmountId), tx3.object(heroId)]
            });
        const result3 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx3,});
        console.log('Transaction Result:', result3);
        let amount = await get_transaction_events(result3.digest);
        // console.log("amount: ",amount);
        if (amount >= 200) {
            break;
        }else{
            continue;
        }
     }catch(error){
         console.log("error");
         continue;
     }
}
// buy box
const tx4 = new Transaction();
tx4.moveCall({
            target: `${PACKAGE_ID}::adventure::buy_box`,
            arguments: [tx4.object(userTokenAmountId),]
        });
const result4 = await client.signAndExecuteTransaction({signer: keypair,transaction: tx4,});
console.log('Transaction Result:', result4);
let newobjectId = await get_newly_created_object(result4.digest);
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
