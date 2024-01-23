// Withdraw.tsx
import { useState } from 'react';

export const Withdraw = () => {
    const [scopeName, setScopeName] = useState('');
    const [amount, setAmount] = useState('');

    const handleSubmit = () => {
        console.log('Withdraw:', scopeName, amount);
        // Add your submission logic here
    };

    return (
        <div className="space-y-4">
            <input
                type="text"
                value={scopeName}
                onChange={(e) => setScopeName(e.target.value)}
                placeholder="Scope Name"
                className="w-full p-2 border border-gray-300 rounded"
            />
            <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="Amount"
                className="w-full p-2 border border-gray-300 rounded"
            />
            <button
                onClick={handleSubmit}
                className="w-full bg-green-500 text-white p-2 rounded hover:bg-green-600"
            >
                Withdraw
            </button>
        </div>
    );
};
