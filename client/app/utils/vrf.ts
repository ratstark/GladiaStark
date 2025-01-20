import { Call } from "starknet";

export const VRF_PROVIDER_ADDRESS = '0x051fea4450da9d6aee758bdeba88b2f665bcbf549d2c61421aa724e9ac0ced8f';

export enum SourceType {
    Nonce = 0,
    Salt = 1,
}

export interface VrfSource {
    type: SourceType;
    value: string; // address for Nonce, felt252 for Salt
}

export function createVrfRequest(gameContract: string, source: VrfSource): Call {
    return {
        contractAddress: VRF_PROVIDER_ADDRESS,
        entrypoint: 'request_random',
        calldata: [
            gameContract,
            source.type,
            source.value
        ]
    };
}
