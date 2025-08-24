import { Transaction } from '@mysten/sui/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import axios from 'axios';


const secretKey = 'suiprivkey1qqsqnl67wmxvme3sv34endnujtr8yp0638vekzt9k5ael07qnrgdu52dr9g';
const keypair = Ed25519Keypair.fromSecretKey(secretKey);
const publicKey = keypair.getPublicKey();
const address = publicKey.toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl('testnet') });

const heroId = '0x1b50457fcaa8847711254c443d288950efd0d98d98210af0a806dcbfdb8a3e0d';// heroId
const suiRpcUrl = 'https://fullnode.testnet.sui.io/';

async function get_level() {
    try {
        const response = await axios.post(suiRpcUrl,{jsonrpc: '2.0',id: 1, method: 'sui_getObject',params: [heroId,{showType: true,showOwner: true,showDepth: true,showContent: true,showDisplay: true,},],},{headers: {'Content-Type': 'application/json',},});
        const fields = response.data.result?.data?.content?.fields;
        if (fields) {console.log('Experience:', fields.experience);console.log('Level', fields.level)} else {console.log('No fields found in the object.');}
        return {
            experience: fields.experience,
            level: fields.level,
        };
    } catch (error) {
        console.error('Error fetching object data:', error.message);
    }
}

const { experience, level } = await get_level();
console.log('Experience:', experience);
console.log('Level:', level);