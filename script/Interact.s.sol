// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 public constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 public constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [PROOF_ONE, PROOF_TWO];
    bytes private constant SIGNATURE =
        hex"2c8855d7cbe1062b7d933545a4b5b7f9290a8f886b988f6355effa3980b6830237e9e17437c20a3ce29bde800e0777bbd7f0c08f9b952ebefd22c5f5691998721b";

    error __ClaimAirdropScript__InvalidSignatureLength();

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdrop) public {
        MerkleAirdrop airdropContract = MerkleAirdrop(airdrop);
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        airdropContract.claim(CLAIMING_ADDRESS, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}