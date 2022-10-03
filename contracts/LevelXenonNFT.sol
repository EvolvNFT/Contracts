// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "./interfaces/IXenonNFT.sol";

abstract contract LevelXenonNFT is ERC721Royalty,IXenonNFT {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private factory;

    string private URI;
    string private extension;

    mapping (uint256 => string) public nftNames;
    mapping (uint256 => uint256) public nftLevels;

    mapping (uint256 => mapping( bytes32 => bool)) public utilities;

    modifier onlyFactory {
        require(msg.sender == factory);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
        ) ERC721(_name, _symbol){

            nftCount = _nftCount;
            factory = msg.sender;
    }

    function setBaseURI(string memory _URI, string memory _ext) public onlyFactory {
        URI = _URI;
        extension = _ext;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        string memory _baseWithTokenID = super.tokenURI(_tokenId);
        return bytes(_baseWithTokenID).length > 0 ? string(abi.encodePacked(_baseWithTokenID, extension)) : "";
    }

    function renameNFT(uint256 _tokenId, string memory _nftName) public override onlyFactory {
        require(_exists(_tokenId), "Rename for nonexistent token");

        nftNames[_tokenId] = _nftName;

        emit NFTrenamed(_tokenId, _nftName);
    }

    function levelUpNFT(uint256 _tokenId) public override onlyFactory {
        require(_exists(_tokenId), "Level Up for nonexistent token");

        nftLevels[_tokenId] += 1;

    }

    function unlockUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory {
        require(_exists(_tokenId), "Unlock utility for nonexistent token");

        utilities[_tokenId][_utilitySlug] = true;

    }

    function levelUpNFTWithUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory{
        require(_exists(_tokenId), "Level Up and Unlock Utility for nonexistent token");

        nftLevels[_tokenId] += 1;
        utilities[_tokenId][_utilitySlug] = true;

    }

    function toggleUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory {
        require(_exists(_tokenId), "Toggle Utility for nonexistent token");

        utilities[_tokenId][_utilitySlug] = utilities[_tokenId][_utilitySlug] ? false : true;
    }

}