/* Functions should be grouped according to their visibility and ordered:
    constructor

    receive function (if exists)

    fallback function (if exists)

    external

    public

    internal

    private
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    /*===============================================
                     Types          
    ===============================================*/

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*===============================================
                     State variables       
    ===============================================*/
    // some list of addresses
    // Allow someone to claim ERC-20 tokens
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 public immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    /*===============================================
                     Events          
    ===============================================*/
    event Claim(address account, uint256 amount);

    /*===============================================
                     Errors          
    ===============================================*/
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /*===============================================
                     Functions          
    ===============================================*/
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Airdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /*===============================================
                External functions          
    ===============================================*/
    /**
     *
     * @param account The account to claimq
     * @param amount The amount to claim
     * @param merkleProof The expected merkle proof
     * @dev following CEI
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        /* Check */
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Check signature
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
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
                    Internal functions          
    ===============================================*/
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    /*===============================================
                View and Pure functions          
    ===============================================*/
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
