// ProposeProtocolFee.tsx
import { useState } from 'react';
import { safeService, web3Service } from '../appServices';
import { ethers } from 'ethers'

import detectEthereumProvider from '@metamask/detect-provider';


export const ProposeProtocolFee = () => {

    const [mintBp, setMintBp] = useState(0);
    const [patchBp, setPatchBp] = useState(0);
    const [assignBp, setAssignBp] = useState(0);


    const handleSubmit = async () => {
        const provider = await detectEthereumProvider();

        if (provider){
            web3Service.getProposeProtocolFeeTxData(mintBp, patchBp, assignBp);
            //const signer = await provider.getSigner();
        }else{
            console.error("No provider found");
        }
        console.log(provider);
        //
    };

    return (
        <div className="space-y-4">
            <div>
                <label htmlFor="mintBp" className="block text-sm font-medium text-gray-700">
                    Mint Basis Points (10000 = 100%)
                </label>
                <input 
                    type="text" 
                    id="mintBp"
                    value={mintBp} 
                    onChange={(e) => setMintBp((parseInt(e.target.value)))} 
                    placeholder="Mint BP" 
                    className="mt-1 w-full p-2 border border-gray-300 rounded"
                />
            </div>

            <div>
                <label htmlFor="patchBp" className="block text-sm font-medium text-gray-700">
                    Patch Basis Points (10000 = 100%)
                </label>
                <input 
                    type="text" 
                    id="patchBp"
                    value={patchBp} 
                    onChange={(e) => setPatchBp(parseInt(e.target.value))} 
                    placeholder="Patch BP" 
                    className="mt-1 w-full p-2 border border-gray-300 rounded"
                />
            </div>

            <div>
                <label htmlFor="assignBp" className="block text-sm font-medium text-gray-700">
                    Assign Basis Points (10000 = 100%)
                </label>
                <input 
                    type="text" 
                    id="assignBp"
                    value={assignBp} 
                    onChange={(e) => setAssignBp(parseInt(e.target.value))} 
                    placeholder="Assign BP" 
                    className="mt-1 w-full p-2 border border-gray-300 rounded"
                />
            </div>

            <button 
                onClick={handleSubmit}
                className="w-full bg-blue-500 text-white p-2 rounded hover:bg-blue-600"
            >
                Submit
            </button>
        </div>
    );
};
