source .env
# forge script script/DeployPFPDAO.s.sol:Deploy --chain-id 80001 --fork-url $TESTNET_RPC_URL --etherscan-api-key $POLYGONSCAN_API_KEY --resume --verify -vvv

# forge script script/SetUpPool.s.sol:SetUpPool --chain-id 80001 --fork-url $TESTNET_RPC_URL --broadcast

# forge script script/UpgradePool.s.sol:UpgradePool --chain-id 80001 --fork-url $TESTNET_RPC_URL --broadcast
# forge verify-contract 0xf08b3e7098d206610142e08ead690629e1cd2663 PFPDAOPool $POLYGONSCAN_API_KEY --verifier-url https://api-testnet.polygonscan.com/api