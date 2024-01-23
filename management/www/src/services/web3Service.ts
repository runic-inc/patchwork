import {
    getContract,
    prepareWriteContract,
    waitForTransaction,
    writeContract,
} from 'wagmi/actions';
import { configService } from '../appServices';

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

}
