// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
    A Merkle tree is a data structure used for data verification and synchronization. 
    It’s a tree-like structure where each non-leaf node is a hash of its child nodes, 
    and all leaf nodes are at the same depth and as far left as possible.

    Key Characteristics:
    Each leaf node is a hash of a block of data
    Non-leaf nodes are hashes of their children
    Typically, Merkle trees have a branching factor of 2, meaning each node has up to 2 children
    Used for data verification and synchronization

    A Merkle tree can be represented as the following data structure, 
    made of address and amount pairs. These values are used to calculate the leaf hash and, along with the provided proofs, to compute a root hash. 
    This computed root hash is then compared to the expected root hash provided in the constructor of the `MerkleAirdrop` contract.


    root hash
    merkle tree
    merkle proofs
 */
/**
 * @title MerkleAirdrop contract
 * @author s3bc40
 * @notice Learning Merkle tree system applied for Airdrops
 */
contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    /*===============================================
                     State variables       
    ===============================================*/
    // some list of addresses
    // Allow someone to claim ERC-20 tokens

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 public immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    /*===============================================
                     Events          
    ===============================================*/
    event Claim(address account, uint256 amount);

    /*===============================================
                     Errors          
    ===============================================*/
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    /*===============================================
                     Functions          
    ===============================================*/
    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     *
     * @param account The account to claim
     * @param amount The amount to claim
     * @param merkleProof The expected merkle proof
     * @dev following CEI
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        /* Check */
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        /* Effect */
        // calculate using the account and the amount, the hash -> the leaf node
        // Hashing twice to prevent collisions
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        /* Interact */
        i_airdropToken.safeTransfer(account, amount);
    }

    /*===============================================
                     Getter functions          
    ===============================================*/
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
