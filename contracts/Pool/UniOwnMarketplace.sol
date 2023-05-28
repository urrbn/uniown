// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function fee() external view returns (uint256 royalty);

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);

    function owner() external view returns (address owner);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract UniOwnMarketplace is Ownable {

    struct AuctionItem {
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        uint256 askingPrice;
        bool isSold;
    }

    AuctionItem[] public itemsForSale;

    //to check if item is open to market
    mapping(address => mapping(uint256 => bool)) public activeItems;
    mapping(address => mapping(uint256 => uint256)) public auctionItemId;
  

    event ItemAdded(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice);
    event ItemSold(uint256 id, address buyer, uint256 askingPrice);
    


    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "OnlyItemOwner");
        _;
    }


    modifier HasTransferApproval(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this), "MarketPlace:No Transfer Approval");
        _;
    }

    modifier ItemExists(uint256 id) {
        require(id <= itemsForSale.length, "Could not find Item");
        _;
    }


    function addItemToMarket(
        uint256 tokenId,
        address tokenAddress,
        uint256 askingPrice
    ) external OnlyItemOwner(tokenAddress, tokenId) HasTransferApproval(tokenAddress, tokenId) returns (uint256) {
        require(activeItems[tokenAddress][tokenId] != true, "Item is already up for sale");
       
        return _addItemSimple(tokenId, tokenAddress, askingPrice);
       
    }

    function _addItemSimple(
        uint256 tokenId,
        address tokenAddress,
        uint256 askingPrice
    ) internal returns (uint256) {
        //item is being added for the first time in marketplace
        uint256 newItemId = itemsForSale.length + 1;
        itemsForSale.push(
            AuctionItem(newItemId, tokenAddress, tokenId, askingPrice, false)
        );
        activeItems[tokenAddress][tokenId] = true;
        auctionItemId[tokenAddress][tokenId] = newItemId;
        assert(itemsForSale[newItemId - 1].id == newItemId);
        emit ItemAdded(newItemId, tokenId, tokenAddress, askingPrice);
        return newItemId;
       
    }

    function buyItem(uint256 id)
        external
        payable
        ItemExists(id)
        HasTransferApproval(itemsForSale[id - 1].tokenAddress, itemsForSale[id - 1].tokenId)
    {
        require(
            activeItems[itemsForSale[id - 1].tokenAddress][itemsForSale[id - 1].tokenId],
            "Item not listed in market"
           
        );
        require(itemsForSale[id - 1].isSold == false, "Item already sold");
        IERC721 Collection = IERC721(itemsForSale[id - 1].tokenAddress);
        address itemOwner = Collection.ownerOf(itemsForSale[id - 1].tokenId);
        require(msg.sender != itemOwner, "Seller cannot buy item");
        require(msg.value >= itemsForSale[id - 1].askingPrice, "Not enough funds sent");
        _buyitemSimple(id);
    }


    function _buyitemSimple(uint256 id) internal {
        IERC721 Collection = IERC721(itemsForSale[id - 1].tokenAddress);
        address itemOwner = Collection.ownerOf(itemsForSale[id - 1].tokenId);
        
        (bool success, ) = itemOwner.call{value: msg.value}("");
       
        require(success, "Failed to send Ether");


        itemsForSale[id - 1].isSold = true;
        activeItems[itemsForSale[id - 1].tokenAddress][itemsForSale[id - 1].tokenId] = false;
        IERC721(itemsForSale[id - 1].tokenAddress).safeTransferFrom(
            Collection.ownerOf(itemsForSale[id - 1].tokenId),
            msg.sender,
            itemsForSale[id - 1].tokenId
        );
        
        emit ItemSold(id, msg.sender, itemsForSale[id - 1].askingPrice);
    }


    function printOwner(address _collectionAddress) public view returns (address) {
        return IERC721(_collectionAddress).owner();
    }
}