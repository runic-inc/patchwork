import { ethers } from 'ethers'
import { configService } from '../appServices';
import Safe from '@safe-global/protocol-kit'
import { MetaTransactionData } from '@safe-global/safe-core-sdk-types'

import { createPublicClient, http, parseAbiItem } from 'viem';
import { zoraSepolia } from 'wagmi/chains';
import patchworkABI from '../../../../out/PatchworkProtocol.sol/PatchworkProtocol.json'
import { ManagementConfig } from '../types/types';

export class Web3Service {

    private publicClient: any;
    private managementConfig: ManagementConfig;

    constructor() {
        this.managementConfig = configService.getManagementConfig();

        const client = createPublicClient({
            chain: zoraSepolia,
            transport: http(),
        });
        this.publicClient = client;
    }

    public async getProposeProtocolFeeTxData(mintBp: number, patchBp: number, assignBp: number) : Promise<MetaTransactionData> {

        const contract = new ethers.Contract(this.managementConfig.patchworkAddress, patchworkABI.abi);

        const feeConfig = {
            mintBp: mintBp,
            patchBp: patchBp,
            assignBp: assignBp
        };

        const data = contract.interface.encodeFunctionData('proposeProtocolFeeConfig', [feeConfig]);

        const safeTransactionData: MetaTransactionData = {
            to: await contract.getAddress(),
            value: '0',
            data: data
        }        
        console.log(safeTransactionData);
        return safeTransactionData;
    }

}
