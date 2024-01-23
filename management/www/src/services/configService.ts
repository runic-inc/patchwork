import { ManagementConfig } from "../types/types";
import { Chain } from 'wagmi';
import { base, sepolia } from 'wagmi/chains';

interface NetworkConfig {
    rpcUrl: string;
    patchworkSafe: `0x${string}`;
    patchworkAddress: `0x${string}`;
    chain: Chain;
}

const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
    base: {
        rpcUrl: import.meta.env.BASE_RPC_URL,
        patchworkSafe: import.meta.env.BASE_PATCHWORK_OWNER as `0x${string}`,
        patchworkAddress: import.meta.env.BASE_PATCHWORK_ADDRESS as `0x${string}`,
        chain: base
    },
    sepolia: {
        rpcUrl: import.meta.env.SEPOLIA_RPC_URL,
        patchworkSafe: import.meta.env.SEPOLIA_PATCHWORK_OWNER as `0x${string}`,
        patchworkAddress: import.meta.env.SEPOLIA_PATCHWORK_ADDRESS as `0x${string}`,
        chain: sepolia
    },
};


export class ConfigService {
    private managementConfig: ManagementConfig;

    constructor() {
        const network = import.meta.env.VITE_NETWORK || 'base';
        const networkConfig = NETWORK_CONFIGS[network];
        if (!networkConfig) {
            throw new Error(`Configuration for network '${network}' not found.`);
        }
        
        this.managementConfig = {
            rpcUrl: networkConfig.rpcUrl,
            patchworkSafe: networkConfig.patchworkSafe,
            patchworkAddress: networkConfig.patchworkAddress,
            chain: networkConfig.chain,
            wagmiProjectId: import.meta.env.WAGMI_PROJECT_ID
        };
    }

    getManagementConfig(): ManagementConfig {
        console.log(this.managementConfig);
        return this.managementConfig;
    }

}
