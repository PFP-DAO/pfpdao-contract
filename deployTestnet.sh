source .env

forge script script/DeployPFPDAO.s.sol:Deploy --chain-id $CHAIN --fork-url $RPC_URL 
# forge script script/InitPFPDAO.s.sol:InitPFPDAO --chain-id $CHAIN --fork-url $RPC_URL -vvv

# forge script script/AddExp.s.sol:AddExp --chain-id $CHAIN --fork-url $RPC_URL  --broadcast --via-ir  -vvv

# forge script script/DeployEquipMetadataDescriptor.s.sol:DeployEquipMetadataDescriptor --chain-id $CHAIN --fork-url $RPC_URL --broadcast --verify -vv
# forge verify-contract 0xb2e268d2b3d52842Da11146211D3cBD797570554 PFPDAOEquipMetadataDescriptor --watch

# forge verify-contract 0x2270b742C9FBf25410f256a20e1c2Ac64F7c3ecF PFPDAORole --watch

# cast call $POOL_ADDRESS "getupSSIdsLength()(uint256)" --rpc-url $RPC_URL
# cast call $POOL_ADDRESS "activeNonce()(uint8)" --rpc-url $RPC_URL

# forge script script/Test3525.s.sol:TestERC3525Script --fork-url $RPC_URL -vv --broadcast
# forge verify-contract --constructor-args $(cast abi-encode "constructor(string, string, uint8)" "Test" "TEST" 0) 0x8A0DbeF77406583745F4f10B37557aa7130aA7D8 src/Test3525.sol:TestERC3525 --watch

# forge script script/SetUpPool.s.sol:SetUpPool --chain-id $CHAIN --fork-url $RPC_URL -vv

# forge script script/UpgradeEquipMetadataDescriptor.s.sol:UpgradeEquipMetadataDescriptor --chain-id $CHAIN --fork-url $RPC_URL -vv

# forge script script/UpgradePool.s.sol:UpgradePool --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract  0x66d849084de11c753193f945649c39e61a982b9f PFPDAOPool $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/UpgradeRole.s.sol:UpgradeRole --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge script script/Airdrop.s.sol:Airdrop --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract  0x61c5B27d18Df92151f40dBc12B88B57C7980bd6a PFPDAORole $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL --optimizer-runs=100 --show-standard-json-input > etherscan.json
# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(address,bytes)" 0x76FD1559E1B753b072b1523AB1C03aBe12916F28 "") \
# 0x819Fb32538862d5E788937CADcfa2FD8764A7c84 src/UUPSProxy.sol:UUPSProxy $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL  --optimizer-runs=100 --show-standard-json-input > etherscan.json


# forge script script/UpgradeEquip.s.sol:UpgradeEquip --chain-id $CHAIN --fork-url $RPC_URL --verify  --broadcast -vv 

# forge script script/DeployOGColourSBT.s.sol:D/eploySBT --chain-id $CHAIN --fork-url $RPC_URL --etherscan-api-key $POLYGONSCAN_API_KEY --broadcast -vvvv
# forge verify-contract 0x6DB49aF834786c85B8D8caB9246eEF9DA928f362 src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(address,string)" 0x6be1DF185D5fa3ed4220301E18d1ad64BC126b4A "") \
# 0xE9728Ed5E1FD05665C44a17082d77049801435f0 src/UUPSProxy.sol:UUPSProxy  $POLYGONSCAN_API_KEY  --verifier-url $VERIFIER_URL

# forge script script/UpgradeOGColourSBT.s.sol:UpgradeOGColourSBT --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract 0x8CF168b08D0f8776FB8cf9B1aEB47DE8EF61262A src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/ComputeSlot.s.sol:ComputeSlot --chain-id $CHAIN --fork-url $RPC_URL 
# forge script script/ReadPoolStatus.s.sol:ReadStatus --chain-id $CHAIN --fork-url $RPC_URL 