// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IBatchUpdate.sol";
import "./interfaces/IFactory.sol";

import "./Factory.sol";

contract BatchUpdate {
    address private oracle;
    address private owner;
    address private factory;
    // List of Merkle Root according to slot
    mapping(uint256 => bytes32) public merkleRoot;

    // slot -> index 
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address owner_, address oracle_, address factory_) {
        owner = owner_;
        oracle = oracle_;
        factory = factory_;
    }

    function isClaimed(uint256 slot, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[slot][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 slot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[slot][claimedWordIndex] = claimedBitMap[slot][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function setMerkleRoot(uint256 slot, bytes32 root) public onlyOracle {
        merkleRoot[slot] = root;
    }

    function changeAdmin(address _admin) public onlyOwner{
        console.log("Changing admin from '%s' to '%s'", owner, _admin);
        owner = _admin;
    }

    function changeFactory(address _factory) public onlyOwner{
        console.log("Changing factory from '%s' to '%s'", factory, _factory);
        factory = _factory;
    }

    function changeOracle(address _oracle) public onlyOwner{
        console.log("Changing oracle from '%s' to '%s'", oracle, _oracle);
        oracle = _oracle;
    }

    function claim(uint256 slot, uint256 index, address account, address nftAddress, uint256 tokenId, string memory utilitySlug, bytes32[] calldata merkleProof) external {
        require(!isClaimed(slot, index), 'MerkleDistributor: Utility already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, nftAddress, tokenId, utilitySlug));
        require(MerkleProof.verify(merkleProof, merkleRoot[slot], node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and upgrade the utility.
        _setClaimed(slot, index);

        IFactory factoryContract = IFactory(factory);
        factoryContract.levelUpNFTWithUtility(nftAddress, tokenId, utilitySlug);
    }
}