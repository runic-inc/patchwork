// RemoveBanker.tsx
import { useState } from 'react';

export const RemoveBanker = () => {
    const [ethAddress, setEthAddress] = useState('');

    const handleSubmit = () => {
        console.log('Removing Banker:', ethAddress);
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
                className="w-full bg-red-500 text-white p-2 rounded hover:bg-red-600"
            >
                Remove Banker
            </button>
        </div>
    );
};
