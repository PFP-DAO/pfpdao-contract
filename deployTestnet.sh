source .env

# forge script script/DeployPFPDAO.s.sol:Deploy --chain-id $CHAIN --fork-url $RPC_URL --broadcast --via-ir  -vvv
# forge script script/InitPFPDAO.s.sol:InitPFPDAO --chain-id $CHAIN --fork-url $RPC_URL --broadcast --via-ir -vvvv

# forge script script/DeployEquipMetadataDescriptor.s.sol:DeployEquipMetadataDescriptor --chain-id $CHAIN --fork-url $RPC_URL --broadcast --via-ir  -vvv
# forge verify-contract 0x7b72A93777Dbe6D5309Db43d6d476EeC651d6eB7 src/PFPDAOEquipMetadataDescriptor.sol:PFPDAOEquipMetadataDescriptor --watch

# cast call $POOL_ADDRESS "getUpRareIdsLength()(uint256)" --rpc-url $RPC_URL
# cast call $POOL_ADDRESS "activeNonce()(uint8)" --rpc-url $RPC_URL

# forge script script/Test3525.s.sol:TestERC3525Script --fork-url $RPC_URL -vv --broadcast
# forge verify-contract --constructor-args $(cast abi-encode "constructor(string, string, uint8)" "Test" "TEST" 0) 0x8A0DbeF77406583745F4f10B37557aa7130aA7D8 src/Test3525.sol:TestERC3525 --watch

# forge script script/SetUpPool.s.sol:SetUpPool --chain-id $CHAIN --fork-url $RPC_URL -vv

# forge script script/UpgradePool.s.sol:UpgradePool --chain-id $CHAIN --fork-url $RPC_URL -vv
# forge verify-contract  0x66d849084de11c753193f945649c39e61a982b9f PFPDAOPool $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/UpgradeRole.s.sol:UpgradeRole --chain-id $CHAIN --fork-url $RPC_URL --broadcast -vv
# forge verify-contract  0x472ee4fd6581f5eb1c3264e2295ec3771bc145e5 PFPDAORole $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL
# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(string,string)" "PFPDAORoleA" "PFPRA") \
# 0xbE0A8ce3Ca98d5806B7f8dA015eaBcFb4738592A src/UUPSProxy.sol:UUPSProxy $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/UpgradeEquip.s.sol:UpgradeEquip --chain-id $CHAIN --fork-url $RPC_URL  --broadcast -vv 

# forge script script/DeployOGColourSBT.s.sol:D/eploySBT --chain-id $CHAIN --fork-url $RPC_URL --etherscan-api-key $POLYGONSCAN_API_KEY --broadcast -vvvv
# forge verify-contract 0x6DB49aF834786c85B8D8caB9246eEF9DA928f362 src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(address,string)" 0x6be1DF185D5fa3ed4220301E18d1ad64BC126b4A "") \
# 0xE9728Ed5E1FD05665C44a17082d77049801435f0 src/UUPSProxy.sol:UUPSProxy  $POLYGONSCAN_API_KEY  --verifier-url $VERIFIER_URL

# forge script script/UpgradeOGColourSBT.s.sol:UpgradeOGColourSBT --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract 0x8CF168b08D0f8776FB8cf9B1aEB47DE8EF61262A src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/ComputeSlot.s.sol:ComputeSlot --chain-id $CHAIN --fork-url $RPC_URL 
# forge script script/ReadPoolStatus.s.sol:ReadStatus --chain-id $CHAIN --fork-url $RPC_URL 