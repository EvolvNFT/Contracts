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

    address payable treasury;
    address owner;
    uint256 royalty;
    uint256 royaltyScale;

    constructor(address payable _treasury, uint256 _royalty, uint256 _royaltyScale){
        require((_royalty/_royaltyScale)<100,"Error: Royalty cannot be more than 100");

        treasury=_treasury;
        royalty=_royalty;
        royaltyScale=_royaltyScale;
        owner = msg.sender;
    }

    mapping(address=>uint256) userBalance;
    
    struct NFT{
        uint256 salePrice;
        uint256 endTime;
        address payable owner;
        address payable buyer;
        bool onSale;
        bool isEthSale;
        address salesTokenAddress;        
    }

    mapping(address=>mapping(uint256=>NFT)) NFTs; //store details of NFT on auction

    bool internal locked;

    modifier noReentrant() {
        require(!locked,"No re-entrancy");
        locked=true;
        _;
        locked=false;
    }

    modifier onlyOwner() {
        require(msg.sender==owner,"Error: Can only be accessed by Owner");
        _;
    }

    function listNFTforSale(address nftAddress, uint256 tokenID, uint256 _endTime, uint256 _salePrice, bool _isETHSale, address _salesTokenAddress) public whenNotPaused{ 
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==nft.ownerOf(tokenID),"Error: You must be the owner of NFT");
        require(NFTs[nftAddress][tokenID].onSale==false,'Error: The NFT is already on Sale');

        nft.transferFrom(msg.sender, address(this), tokenID);

        NFT memory nft1 = NFT(_salePrice, _endTime, payable(msg.sender), payable(0x0000000000000000000000000000000000000000), true, _isETHSale, _salesTokenAddress);
        NFTs[nftAddress][tokenID] = nft1;

    }

    function revertNFTfromSale(address nftAddress, uint256 tokenID) public noReentrant whenNotPaused{ 
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==NFTs[nftAddress][tokenID].owner,'Error: You must be the owner of NFT');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT must be on sale to cancel listing');
        
        nft.transferFrom(address(this),msg.sender,tokenID);

        NFTs[nftAddress][tokenID].onSale=false;
    }


    function buyWithETH(address nftAddress, uint256 tokenID) public payable noReentrant whenNotPaused{
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(NFTs[nftAddress][tokenID].owner!=msg.sender,'Error: The owner cannot buy the NFT');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Error: Please switch to token Sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT is not listed on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Error: The Sale for NFT has ended');

        require(msg.value>=NFTs[nftAddress][tokenID].salePrice,"Error: Does not meet the Sale Price Cost");

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

        IERC20 salesToken = IERC20(NFTs[nftAddress][tokenID].salesTokenAddress);
            
        require(salesToken.balanceOf(msg.sender)>=NFTs[nftAddress][tokenID].salePrice,'Error: value sent is lower than minimum cost');
            
        userBalance[NFTs[nftAddress][tokenID].owner]+=((salesToken.balanceOf(address(this))*(100-royalty)))/royaltyScale;
        userBalance[treasury]+=(salesToken.balanceOf(address(this))*royalty)/royaltyScale;
        userBalance[NFTs[nftAddress][tokenID].buyer]+=salesToken.balanceOf(address(this));

        NFTs[nftAddress][tokenID].buyer=payable(msg.sender);

        salesToken.transferFrom(msg.sender, address(this), NFTs[nftAddress][tokenID].salePrice);

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].buyer,tokenID);

    }

    function withdrawETH() public whenNotPaused{
        uint256 balance = userBalance[msg.sender];
        require(balance>0,'Error: There is no ETH to transfer');

        address payable _treasuryAddress = payable(msg.sender);

        (bool _sent,) = _treasuryAddress.call{value: balance}("");
        require(_sent, "Error: Failed to send Ether");

        userBalance[msg.sender]=0;
    }

    function withdrawYourToken(address _salesToken) public whenNotPaused{
        IERC20 salesToken = IERC20(_salesToken);

        uint256 _contractBalance = salesToken.balanceOf(msg.sender);
        require( _contractBalance > 0 , "Error: No Token accumulated");
        salesToken.transfer(msg.sender, _contractBalance);

    }

    function getBalance() public view returns(uint256){
        return userBalance[msg.sender];
    }

    function changeRoyalty(uint256 _royalty, uint256 _royaltyScale) public onlyOwner whenNotPaused{
        require((_royalty/_royaltyScale)<100,'Error: Royalty cannot exceed 100%');

        royalty = _royalty;
    }

    function changeTreasury(address payable _treasury) public onlyOwner whenNotPaused{
        treasury = payable(_treasury);
    }

    function TogglePause() public view onlyOwner{
        if(paused()==false)
            _pause;
        else
            _unpause;
    }

}