source .env

# forge script script/DeployPFPDAO.s.sol:Deploy --chain-id $CHAIN --fork-url $RPC_URL 

# forge script script/SetNonce.s.sol:SetNonce --chain-id $CHAIN --fork-url $RPC_URL -vv --broadcast
# forge script script/Withdraw.s.sol:Withdraw --chain-id $CHAIN --fork-url $RPC_URL -vv --broadcast

# forge script script/UpgradePool.s.sol:UpgradePool --chain-id $CHAIN --fork-url $RPC_URL --optimizer-runs=0 --via-ir
# forge verify-contract 0x861D091713a8cf12172736CD8D53fec31b7b9751 src/PFPDAOPool.sol:PFPDAOPool $POLYGONSCAN_API_KEY --libraries src/libraries/Helpers.sol:Helpers:0x7d0be4747e3048c121aecfc37c04e5da8351bab4 --verifier-url $VERIFIER_URL --compiler-version 0.8.18 --watch
# forge verify-contract 0x7D6b1DD0A970c9929D6e2cDF289F0F209d2D7E78 src/libraries/Utils.sol:Utils $POLYGONSCAN_API_KEY --optimizer-runs=0 --show-standard-json-input > Utils.json
# forge verify-contract 0x3160832a191t88405D5B8Cc7438B9E1f6E9f2Bb39 src/PFPDAOPool.sol:PFPDAOPool $POLYGONSCAN_API_KEY  --libraries src/libraries/Utils.sol:Utils:0x7D6b1DD0A970c9929D6e2cDF289F0F209d2D7E78 --optimizer-runs=0 --show-standard-json-input > PFPDAOPool.json
# forge verify-contract 0xd09E7b191D55E3e2431E5761D4a1d190605a3759 src/PFPDAORole.sol:PFPDAORole $POLYGONSCAN_API_KEY --libraries src/libraries/Utils.sol:Utils:0x7D6b1DD0A970c9929D6e2cDF289F0F209d2D7E78 --optimizer-runs=0 --show-standard-json-input > PFPDAORole0.json

# forge script script/DeployDividend.s.sol:DeployDividend --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract  0xdf51b83054C87B6A3D5D4b277fe8F7f271e5d1fE Dividend $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge verify-contract 0xBbF5B7EB6743dbEBD09757b199c1f47B564D5121 PFPDAORole  $POLYGONSCAN_API_KEY --optimizer-runs=0 --show-standard-json-input > PFPDAORole.json

# 2. patch manually etherscan,json : "optimizer": {"enabled":true,"runs":100) -> "optimizer":{"enabled":true, "runs":100}, "viaIR":true

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

# forge script script/UpgradeRole.s.sol:UpgradeRole --chain-id $CHAIN --fork-url $RPC_URL --libraries src/libraries/Helpers.sol:Helpers:0x7d0be4747e3048c121aecfc37c04e5da8351bab4 --verify --via-ir -vv

# forge script script/Airdrop.s.sol:Airdrop --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge script script/Withdraw.s.sol:Withdraw --chain-id $CHAIN --fork-url $RPC_URL

# forge verify-contract  0x61c5B27d18Df92151f40dBc12B88B57C7980bd6a PFPDAORole $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL --optimizer-runs=100 --show-standard-json-input > etherscan.json
# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(address,bytes)" 0x24291D6c51f6Cc45C2dC3C8Ee5684FA81BDC82A6 "") \
# 0x819Fb32538862d5E788937CADcfa2FD8764A7c84 src/UUPSProxy.sol:UUPSProxy $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL  --optimizer-runs=100 --show-standard-json-input > etherscan.json


# forge script script/UpgradeEquip.s.sol:UpgradeEquip --chain-id $CHAIN --fork-url $RPC_URL --verify  --broadcast -vv 

# forge script script/DeployOGColourSBT.s.sol:D/eploySBT --chain-id $CHAIN --fork-url $RPC_URL --etherscan-api-key $POLYGONSCAN_API_KEY --broadcast -vvvv
# forge verify-contract 0x6DB49aF834786c85B8D8caB9246eEF9DA928f362 src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL
# forge verify-contract 0x05DadFf0CFe21692326837402fB6E7FE27707FCe src/PFPDAOStyleVariantManager.sol:PFPDAOStyleVariantManager $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge verify-contract \
# --constructor-args $(cast abi-encode "constructor(address,string)" 0xdf51b83054C87B6A3D5D4b277fe8F7f271e5d1fE "") \
# 0x24291D6c51f6Cc45C2dC3C8Ee5684FA81BDC82A6 src/UUPSProxy.sol:UUPSProxy  $POLYGONSCAN_API_KEY  --verifier-url $VERIFIER_URL

# forge script script/UpgradeOGColourSBT.s.sol:UpgradeOGColourSBT --chain-id $CHAIN --fork-url $RPC_URL --broadcast
# forge verify-contract 0x8CF168b08D0f8776FB8cf9B1aEB47DE8EF61262A src/OGColourSBT.sol:OGColourSBT $POLYGONSCAN_API_KEY --verifier-url $VERIFIER_URL

# forge script script/ComputeSlot.s.sol:ComputeSlot --chain-id $CHAIN --fork-url $RPC_URL 
# forge script script/ReadPoolStatus.s.sol:ReadStatus --chain-id $CHAIN --fork-url $RPC_URL 