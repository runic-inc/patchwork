import { useState } from 'react';
import { Command } from '../types/types';
import { ProposeProtocolFee } from '../compoonents/proposeProtocolFee';
import { AddBanker } from '../compoonents/addBanker';
import { RemoveBanker } from '../compoonents/removeBanker';
import { Withdraw } from '../compoonents/withdrawal';

const commandList = [
    {
        id: 1,
        title: "proposeProtocolFee",
        description: "Propose new Patchwork Protocol Fee",
    },
    {
        id: 2,
        title: "addBanker",
        description: "Add a new banker",
    },
    {
        id: 3,
        title: "removeBanker",
        description: "Remove an existing banker",
    },
    {
        id: 4,
        title: "withdraw",
        description: "Withdraw an amount",
    },
    // ... other commands as needed
];

export default function Commands() {
    const [selectedCommand, setSelectedCommand] = useState<Command | null>(null);

    const handleClick = (command: Command) => {
        setSelectedCommand(command);
    };

    return (
        <div className="pt-40 flex gap-8">
            {/* Command List */}
            <div className="flex-grow grid grid-cols-[repeat(auto-fill,_minmax(150px,_1fr))] gap-4">
                {commandList.map((command) => (
                    <div
                        key={command.id}
                        className="bg-blue-500 cursor-pointer p-4 rounded-lg"
                        onClick={() => handleClick(command)}
                    >
                        {command.title}
                    </div>
                ))}
            </div>

            {/* Command Details */}
            {selectedCommand && (
                <div className="flex-initial w-1/3 bg-gray-100 p-4 rounded-lg">
                    <h3 className="text-xl font-bold mb-2">{selectedCommand.title}</h3>
                    <p>{selectedCommand.description}</p>
                    {selectedCommand.title === "proposeProtocolFee" && <ProposeProtocolFee />}
                    {selectedCommand.title === "addBanker" && <AddBanker />}
                    {selectedCommand.title === "removeBanker" && <RemoveBanker />}
                    {selectedCommand.title === "withdraw" && <Withdraw />}
                </div>
            )}
        </div>
    );
}