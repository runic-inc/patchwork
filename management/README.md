Create a .env file in the format of .env.example

To deoploy on sepolia:
./deploy.sh sepolia

To deploy on base:
./deploy.sh base

Include --broadcast when you are ready to deploy

To verify on ether scan:

./verify.sh base
 
 or

 ./verify.sh sepolia

manual verification:

forge verify-contract 0x635BDfB811Ef377a759231Ac3A2746814A93a7B8 src/PatchworkProtocol.sol:PatchworkProtocol --optimizer-runs 200 --constructor-args "0x0000000000000000000000007239aec2fa59303ba68bece386be2a9ddc72e63b" --show-standard-json-input > etherscan.json
patch manually etherscan.json : "optimizer":{"enabled":true,"runs":100} -> "optimizer":{"enabled":true,"runs":100},"viaIR":true (or something of that sort)
upload json to etherscan manually