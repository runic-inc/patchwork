// AddBanker.tsx
import { useState } from 'react';

export const AddBanker = () => {
    const [ethAddress, setEthAddress] = useState('');

    const handleSubmit = () => {
        console.log('Adding Banker:', ethAddress);
        // Add your submission logic here
    };

    return (
        <div className="space-y-4">
            <input
                type="text"
                value={ethAddress}
                onChange={(e) => setEthAddress(e.target.value)}
                placeholder="Ethereum Address"
                className="w-full p-2 border border-gray-300 rounded"
            />
            <button
                onClick={handleSubmit}
                className="w-full bg-blue-500 text-white p-2 rounded hover:bg-blue-600"
            >
                Add Banker
            </button>
        </div>
    );
};
