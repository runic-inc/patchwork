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
}

export interface MetaMaskEthereumProvider {
    isMetaMask?: boolean;
    once(eventName: string | symbol, listener: (...args: any[]) => void): this;
    on(eventName: string | symbol, listener: (...args: any[]) => void): this;
    off(eventName: string | symbol, listener: (...args: any[]) => void): this;
    addListener(eventName: string | symbol, listener: (...args: any[]) => void): this;
    removeListener(eventName: string | symbol, listener: (...args: any[]) => void): this;
    removeAllListeners(event?: string | symbol): this;
}