source .env
forge script script/DeployPFPDAO.s.sol:Deploy --chain-id 80001 --fork-url $RPC_URL --etherscan-api-key $POLYGONSCAN_API_KEY --resume --verify -vvv

# forge script script/SetUpPool.s.sol:SetUpPool --chain-id 80001 --fork-url $RPC_URL --broadcast