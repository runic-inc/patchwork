import { Chain } from "wagmi";

export interface ManagementConfig {
    rpcUrl: string;
    patchworkSafe: `0x${string}`;
    patchworkAddress: `0x${string}`;
    wagmiProjectId: string;
    chain: Chain;
}

export interface Command {
    id: number;
    title: string;
    description: string;
    // Add other properties as needed
}
