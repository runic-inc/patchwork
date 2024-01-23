import { configService } from "../appServices";
import { ManagementConfig, MetaMaskEthereumProvider } from "../types/types";
import { MetaTransactionData } from '@safe-global/safe-core-sdk-types'
import { ethers, BrowserProvider } from 'ethers'
import { EthersAdapter, Safe } from '@safe-global/protocol-kit'
import { useWalletClient } from 'wagmi'
import { Signer } from 'ethers';


import SafeApiKit from '@safe-global/api-kit'


export class SafeService {

    private managementConfig: ManagementConfig;
    
    private service: SafeApiKit;

    constructor() {
        this.managementConfig = configService.getManagementConfig();

        //const { data: signer, isError, isLoading } = useWalletClient();
        const chainId = BigInt(this.managementConfig.chain.id);
        this.service = new SafeApiKit({ chainId })

       

    }

    public async test() {
        
        const info = await this.service.getSafeInfo(this.managementConfig.patchworkSafe);
        console.log(info);

    }

    public async signAndSend(data: MetaTransactionData, provider: BrowserProvider){
;

         const ethAdapter = new EthersAdapter({
            ethers,
            signerOrProvider: provider
          })

          const protocolKit = await Safe.create({
            ethAdapter,
            safeAddress: config.SAFE_ADDRESS
          })

    }

}