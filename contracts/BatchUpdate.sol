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

    constructor(address _owner, address _oracle, address _factory) {
        owner = _owner;
        oracle = _oracle;
        factory = _factory;
    }

    function isClaimed(uint256 _slot, uint256 _index) public view returns (bool) {
        uint256 _claimedWordIndex = _index / 256;
        uint256 _claimedBitIndex = _index % 256;
        uint256 _claimedWord = claimedBitMap[_slot][_claimedWordIndex];
        uint256 _mask = (1 << _claimedBitIndex);
        return _claimedWord & _mask == _mask;
    }

    function _setClaimed(uint256 _slot, uint256 _index) private {
        uint256 _claimedWordIndex = _index / 256;
        uint256 _claimedBitIndex = _index % 256;
        claimedBitMap[_slot][_claimedWordIndex] = claimedBitMap[_slot][_claimedWordIndex] | (1 << _claimedBitIndex);
    }

    function setMerkleRoot(uint256 _slot, bytes32 _root) public onlyOracle {
        merkleRoot[_slot] = _root;
    }

    function changeAdmin(address _owner) public onlyOwner{
        console.log("Changing admin from '%s' to '%s'", owner, _owner);
        owner = _owner;
    }

    function changeFactory(address _factory) public onlyOwner{
        console.log("Changing factory from '%s' to '%s'", factory, _factory);
        factory = _factory;
    }

    function changeOracle(address _oracle) public onlyOwner{
        console.log("Changing oracle from '%s' to '%s'", oracle, _oracle);
        oracle = _oracle;
    }

    function claim(uint256 _slot, uint256 _index, address _account, address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug, bytes32[] calldata _merkleProof) external {
        require(!isClaimed(_slot, _index), 'MerkleDistributor: Utility already claimed.');

        // Verify the merkle proof.
        bytes32 _node = keccak256(abi.encodePacked(_index, _account, _nftAddress, _tokenId, _utilitySlug));
        require(MerkleProof.verify(_merkleProof, merkleRoot[_slot], _node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and upgrade the utility.
        _setClaimed(_slot, _index);

        IFactory factoryContract = IFactory(factory);
        factoryContract.levelUpNFTWithUtilityFactory(_nftAddress, _tokenId, _utilitySlug);
    }
}