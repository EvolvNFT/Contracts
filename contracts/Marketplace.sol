// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IXenonNFT.sol";

import "./XenonNFT.sol";
import "./Factory.sol";
import "hardhat/console.sol";

contract MarketPlace is Pausable {

    struct Brand {
        string name;
        address owner;
        address payable treasury;
        bool isActive;
        uint256 royalty;
        uint256 royaltyScale;
        address salesTokenAddress;
    }
    
    mapping(address=>uint256) userBalance;
    mapping(address=>mapping(uint256=>NFT)) NFTs;
    mapping(string=>Brand) Brands;
    
    struct NFT{
        string brandID;
        uint256 salePrice;
        uint256 endTime;
        address payable owner;
        address payable buyer;
        bool onSale;
        bool isEthSale;        
    }

     //store details of NFT on auction

    bool internal locked;
    address owner;

    modifier noReentrant() {
        require(!locked,"No re-entrancy");
        locked=true;
        _;
        locked=false;
    }
    
    modifier onlyBrandOwner(string memory BrandID) {
        require(msg.sender==Brands[BrandID].owner,"Error: Can only be accessed by the Brand Owner");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==owner,"Error: Can only be accessed by Owner");
        _;
    }

    constructor(address _owner) {
        console.log("Deploying a Factory with owner:", _owner);
        owner = _owner;
    }

    function onboardBrand(string memory _brandID, address _owner, address payable _treasury, uint256 _royalty, uint256 _royaltyScale, address _salesTokenAddress) public onlyOwner{

        require(!Brands[_brandID].isActive, "Brand already exists");

        console.log("Adding a brand with name '%s' and treasury '%s'", _brandID, _treasury);

        Brands[_brandID] = Brand(_brandID, _owner, _treasury, true, _royalty, _royaltyScale, _salesTokenAddress);

    }


    function listNFTforSale(string memory _brandID, address nftAddress, uint256 tokenID, uint256 _endTime, uint256 _salePrice, bool _isETHSale) public whenNotPaused{ 
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==nft.ownerOf(tokenID),"Error: You must be the owner of NFT");
        require(NFTs[nftAddress][tokenID].onSale==false,'Error: The NFT is already on Sale');

        NFT memory nft1 = NFT(_brandID, _salePrice, _endTime, payable(msg.sender), payable(0x0000000000000000000000000000000000000000), true, _isETHSale);
        NFTs[nftAddress][tokenID] = nft1;

        nft.transferFrom(msg.sender, address(this), tokenID);

    }

    function revertNFTfromSale(address nftAddress, uint256 tokenID) public noReentrant whenNotPaused{ 
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==NFTs[nftAddress][tokenID].owner,'Error: You must be the owner of NFT');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT must be on sale to cancel listing');
        
        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),msg.sender,tokenID);

    }


    function buyWithETH(address nftAddress, uint256 tokenID) public payable noReentrant whenNotPaused{
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(NFTs[nftAddress][tokenID].owner!=msg.sender,'Error: The owner cannot buy the NFT');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Error: Please switch to token Sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT is not listed on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Error: The Sale for NFT has ended');

        require(msg.value>=NFTs[nftAddress][tokenID].salePrice,"Error: Does not meet the Sale Price Cost");

        uint256 royalty = Brands[NFTs[nftAddress][tokenID].brandID].royalty;
        uint256 royaltyScale = Brands[NFTs[nftAddress][tokenID].brandID].royaltyScale;
        address payable treasury = Brands[NFTs[nftAddress][tokenID].brandID].treasury;

        NFTs[nftAddress][tokenID].buyer = payable(msg.sender);

        userBalance[NFTs[nftAddress][tokenID].owner]+=((msg.value)*(100-royalty))/royaltyScale;
        userBalance[treasury]+=((msg.value)*(royalty))/royaltyScale;

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].buyer,tokenID);

    }

    function buyWithToken(address nftAddress, uint256 tokenID) public noReentrant whenNotPaused{ 
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(NFTs[nftAddress][tokenID].owner!=msg.sender,'Error: The owner cannot buy the NFT');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Error: Please switch to token Sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT is not listed on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Error: The Sale for NFT has ended');

        uint256 royalty = Brands[NFTs[nftAddress][tokenID].brandID].royalty;
        uint256 royaltyScale = Brands[NFTs[nftAddress][tokenID].brandID].royaltyScale;
        address payable treasury = Brands[NFTs[nftAddress][tokenID].brandID].treasury;
        address salesTokenAddress = Brands[NFTs[nftAddress][tokenID].brandID].salesTokenAddress;

        IERC20 salesToken = IERC20(salesTokenAddress);
            
        require(salesToken.balanceOf(msg.sender)>=NFTs[nftAddress][tokenID].salePrice,'Error: value sent is lower than minimum cost');
            
        userBalance[NFTs[nftAddress][tokenID].owner]+=((salesToken.balanceOf(address(this))*(100-royalty)))/royaltyScale;
        userBalance[treasury]+=(salesToken.balanceOf(address(this))*royalty)/royaltyScale;
        userBalance[NFTs[nftAddress][tokenID].buyer]+=salesToken.balanceOf(address(this));

        NFTs[nftAddress][tokenID].buyer=payable(msg.sender);

        salesToken.transferFrom(msg.sender, address(this), NFTs[nftAddress][tokenID].salePrice);

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].buyer,tokenID);

    }
//send directly
    function withdrawETH() public whenNotPaused{
        uint256 balance = userBalance[msg.sender];
        require(balance>0,'Error: There is no ETH to transfer');

        address payable _treasuryAddress = payable(msg.sender);

        (bool _sent,) = _treasuryAddress.call{value: balance}("");
        require(_sent, "Error: Failed to send Ether");

        userBalance[msg.sender]=0;
    }

    function withdrawToken(address _salesToken) public whenNotPaused{
        IERC20 salesToken = IERC20(_salesToken);

        uint256 _contractBalance = salesToken.balanceOf(msg.sender);
        require( _contractBalance > 0 , "Error: No Token accumulated");
        salesToken.transfer(msg.sender, _contractBalance);

    }

    function getBalance() public view returns(uint256){
        return userBalance[msg.sender];
    }

    function changeRoyalty(string memory brandID, uint256 _royalty, uint256 _royaltyScale) public onlyBrandOwner(brandID) whenNotPaused{
        require((_royalty/_royaltyScale)<100,'Error: Royalty cannot exceed 100%');

        Brands[brandID].royalty = _royalty;
        Brands[brandID].royaltyScale = _royaltyScale;
    }

    function changeTreasury(string memory brandID, address payable _treasury) public onlyBrandOwner(brandID) whenNotPaused{
        Brands[brandID].treasury = payable(_treasury);
    }

    function TogglePause() public view onlyOwner{
        if(paused()==false)
            _pause;
        else
            _unpause;
    }

}