import { configService } from "../appServices";
import { ManagementConfig, MetaMaskEthereumProvider } from "../types/types";
import { MetaTransactionData } from '@safe-global/safe-core-sdk-types'
import { ethers, BrowserProvider } from 'ethers'
import { EthersAdapter } from '@safe-global/protocol-kit'
import Safe from "@safe-global/protocol-kit"
import { useWalletClient } from 'wagmi'
import { Signer } from 'ethers';


import SafeApiKit from '@safe-global/api-kit'


export class SafeService {

    private managementConfig: ManagementConfig;

    private safeApiKit: SafeApiKit;

    constructor() {
        this.managementConfig = configService.getManagementConfig();

        //const { data: signer, isError, isLoading } = useWalletClient();
        const chainId = BigInt(this.managementConfig.chain.id);
        this.safeApiKit = new SafeApiKit({ chainId })
    }

    public async test() {

        const info = await this.safeApiKit.getSafeInfo(this.managementConfig.patchworkSafe);
        console.log(info);

    }

    public async signAndSend(data: MetaTransactionData, provider: BrowserProvider) {
        ;

        const ethAdapter = new EthersAdapter({
            ethers,
            signerOrProvider: provider
        })

        const protocolKit = await Safe.create({
            ethAdapter,
            safeAddress: this.managementConfig.patchworkSafe
        })

        const safeTransaction = await protocolKit.createTransaction({ transactions: [data] })

        const signer = await provider.getSigner();
        const senderAddress = await signer.getAddress()
        const safeTxHash = await protocolKit.getTransactionHash(safeTransaction)
        const signature = await protocolKit.signTransactionHash(safeTxHash)

        // Propose transaction to the service
        await this.safeApiKit.proposeTransaction({
            safeAddress: await protocolKit.getAddress(),
            safeTransactionData: safeTransaction.data,
            safeTxHash,
            senderAddress,
            senderSignature: signature.data
        })

    }

}