//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./XenonNFT.sol";
import "hardhat/console.sol";

contract Factory {

    address private owner;
    address private oracle;
    struct Brand {
        string name;
        address owner;
        address treasury;
        address nftContract;
        bool isActive;
    }

    mapping (string => Brand) public brands;

    mapping (address => mapping(uint256 => uint256)) nftLevels;
    mapping (address => uint256) addressLevels;

    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, address _oracle) {
        console.log("Deploying a Factory with owner:", _owner);
        owner = _owner;
        oracle = _oracle;
    }

    function onboardBrand(string memory _brandId, string memory _brandName, address _owner, address _treasury, uint256 _salePrice) public onlyOwner{
        require(!brands[_brandId].isActive, "Brand already exists");
        console.log("Adding a brand with name '%s' owner '%s' and treasury '%s'", _brandName, _owner, _treasury);
        address nftAddress = address(new LevelNFT(_brandId, _brandName, _salePrice, _treasury));
        console.log(nftAddress);

        brands[_brandId] = Brand(_brandName, _owner, _treasury, nftAddress, true);
    }

    function onboardExistingBrand(string memory _brandId, string memory _brandName, address _owner, address _treasury, address nftAddress) public onlyOwner{
        require(!brands[_brandId].isActive, "Brand already exists");
        console.log("Adding a brand with name '%s' owner '%s' and treasury '%s'", _brandName, _owner, _treasury);

        brands[_brandId] = Brand(_brandName, _owner, _treasury, nftAddress, true);
    }

    function levelUpNFT(address nftAddress, uint256 tokenId) public onlyOracle{
        nftLevels[nftAddress][tokenId] += 1;
    }

    function levelUpNFTByUser(address nftAddress, uint256 tokenId) public payable{
        nftLevels[nftAddress][tokenId] += 1;
    }

    function getOracle() public view returns (address) {
        return oracle;
    }

    function getAdmin() public view returns (address) {
        return owner;
    }

    function setOracle(address _oracle) public onlyOwner{
        console.log("Changing oracle from '%s' to '%s'", oracle, _oracle);
        oracle = _oracle;
    }

    function changeAdmin(address _admin) public onlyOwner{
        console.log("Changing admin from '%s' to '%s'", owner, _admin);
        owner = _admin;
    }
}