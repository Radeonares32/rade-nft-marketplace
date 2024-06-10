// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

contract RadeNFTMarketplace {
    address public owner;
    uint public NFTId;
    uint public NFTAuctionId;

    struct NFTSaleInfo {
        address contractAddress;
        address seller;
        address buyer;
        uint price;
        uint tokenId;
        bool state;
    }

    struct NFTAuctionInfo {
        address contractAddress;
        address seller;
        address buyer;
        uint minPrice;
        uint maxPrice;
        uint tokenId;
        uint deadlineTime;
        bool state;
    }

    mapping(uint => NFTSaleInfo) public idNFTSaleInfo;
    mapping (uint => NFTAuctionInfo) public  idNFTAuctionInfo;
    constructor() public {
        owner = msg.sender;
    }

    function startSaleNFT(address _contractAddress, uint _price, uint _tokenId) public {
        IERC721 NFT = IERC721(_contractAddress);
        require(NFT.ownerOf(_tokenId) == msg.sender,"You are not owner of this NFT");
        NFT.transferFrom(msg.sender, address(this), _tokenId);
        require(NFT.ownerOf(_tokenId) == address(this));
        idNFTSaleInfo[NFTId] = NFTSaleInfo(_contractAddress,msg.sender,msg.sender,_price,_tokenId,false);
        NFTId++;

    }
    function cancelSaleNFT(uint Id) public {
        NFTSaleInfo memory nftInfo =  idNFTSaleInfo[Id];
        IERC721 NFT = IERC721(nftInfo.contractAddress);
        require(nftInfo.seller == msg.sender);
        require(Id < NFTId);
        require(nftInfo.state == false);
        require(msg.sender == nftInfo.seller);
        require(NFT.ownerOf(nftInfo.tokenId) == msg.sender);

        NFT.transferFrom(address(this), msg.sender, nftInfo.tokenId);
        idNFTSaleInfo[Id] = NFTSaleInfo(address(0),address(0),address(0),0,0,true);
    }
    function startAuctionNFT(address _contractAddress, uint _minPrice, uint _tokenId, uint _deadlineTime) public {
        IERC721 NFT = IERC721(_contractAddress);
        require(NFT.ownerOf(_tokenId) == msg.sender);
        NFT.transferFrom(msg.sender, address(this), _tokenId);
        idNFTAuctionInfo[NFTAuctionId] = NFTAuctionInfo(_contractAddress,msg.sender,msg.sender,_minPrice,0,_tokenId,_deadlineTime,false);
        NFTAuctionId++;

    }
    function cancelAuctionNFT(uint Id) public {
        NFTAuctionInfo memory nftInfo =  idNFTAuctionInfo[Id];
        IERC721 NFT = IERC721(nftInfo.contractAddress);
        require(nftInfo.seller == msg.sender);
        require(Id < NFTAuctionId);
        require(nftInfo.state == false);
        require(msg.sender == nftInfo.seller);
        require(NFT.ownerOf(nftInfo.tokenId) == msg.sender);
        require(nftInfo.buyer == msg.sender);

        NFT.transferFrom(address(this), msg.sender, nftInfo.tokenId);
        idNFTAuctionInfo[Id] = NFTAuctionInfo(address(0),address(0),address(0),0,0,0,0,true);
    }
    function buyNFT(uint Id) public payable {
        NFTSaleInfo storage nftInfo = idNFTSaleInfo[Id];
        require(Id < NFTId);
        require(msg.sender != nftInfo.seller);
        require(msg.value == nftInfo.price);
        require(nftInfo.state == false);

         IERC721 NFT = IERC721(nftInfo.contractAddress);
         NFT.transferFrom(address(this), msg.sender, nftInfo.tokenId);

         uint price = msg.value * 97 / 100;
         payable(nftInfo.seller).transfer(price);
         payable(owner).transfer(msg.value - price);
         nftInfo.buyer = msg.sender;
         nftInfo.state = true;


    }
    function offerNFT(uint Id) public payable {
        NFTAuctionInfo storage nftInfo = idNFTAuctionInfo[Id];
        require(Id < NFTAuctionId);
        require(msg.sender != nftInfo.seller);
        require(msg.sender != nftInfo.buyer);
        require(msg.value >= nftInfo.minPrice);
        require(msg.value > nftInfo.maxPrice);
        require(nftInfo.state == false);
        require(block.timestamp < nftInfo.deadlineTime);

        if(nftInfo.seller == nftInfo.buyer) {
            nftInfo.buyer = msg.sender;
            nftInfo.maxPrice = msg.value;
        } else {
            payable(nftInfo.buyer).transfer(nftInfo.maxPrice);
            nftInfo.buyer = msg.sender;
            nftInfo.maxPrice = msg.value;
        }
    }
    function finishAuctionNFT(uint Id) public  {
        NFTAuctionInfo storage nftInfo = idNFTAuctionInfo[Id];
        require(Id < NFTAuctionId);
        require(msg.sender == nftInfo.buyer);
        require(nftInfo.state == false);
        require(block.timestamp < nftInfo.deadlineTime);

        IERC721 NFT = IERC721(nftInfo.contractAddress);
        NFT.transferFrom(address(this), msg.sender, nftInfo.tokenId);
        uint price = nftInfo.maxPrice * 97 / 100;
        payable(nftInfo.seller).transfer(price);
        payable(owner).transfer(nftInfo.maxPrice - price);
        nftInfo.state = true;

    }
    function changeOwner(address _owner) public {
        require(owner == msg.sender);
        owner = _owner;
    }
}
