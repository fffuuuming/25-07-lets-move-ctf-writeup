import { getFaucetHost, requestSuiFromFaucetV2 } from '@mysten/sui/faucet';

const response = await requestSuiFromFaucetV2({
    host: getFaucetHost('testnet'),  // or 'testnet'
    recipient: '0x0660124982fd10e3c9ed11e55b445e5dee03b8db9408ea87f1c198d83b3f8bf0',
});

console.log('🎉 Faucet response:', response);