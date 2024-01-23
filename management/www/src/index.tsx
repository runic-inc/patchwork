import { createWeb3Modal, defaultWagmiConfig } from '@web3modal/wagmi/react';
import ReactDOM from 'react-dom/client'
import { WagmiConfig } from 'wagmi';
import App from './App.tsx'
import { sepolia, base } from 'wagmi/chains';
import './index.css'

import { configService } from './appServices.tsx'

const projectId = configService.getManagementConfig().wagmiProjectId;
const metadata = {
    name: 'Patchwork Management',
    description: 'App for proposing Patchwork management commands to SAFE',
    url: '',
    icons: [],
};

const chains = [sepolia, base];
const wagmiConfig = defaultWagmiConfig({ chains, projectId, metadata });

createWeb3Modal({
  wagmiConfig,
  projectId,
  chains,
  themeMode: 'dark',
  themeVariables: {
      '--w3m-accent': '#000',
  },
});


const root = ReactDOM.createRoot(
  document.querySelector('#root') as HTMLElement,
);
root.render(
  <WagmiConfig config={wagmiConfig}>
      <App />
  </WagmiConfig>,
);
