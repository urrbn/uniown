// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IUniOwnMarketplace.sol";
import "../interfaces/IUniOwnDaoFactory.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
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


contract UniOwnPool{


    struct Pool {
        uint256 maxAmount;
        uint256 totalAmount;
        uint256 tokenId;
        uint256 endTime;
        uint256 minParticipation;
        uint256 itemId;
        address collection;
        address marketplace;
        bool poolFinished;
        bool poolSuccessful;
    }

    // Sale
    Pool public pool;

    address public factory;

    address[] public allParticiapnts;
    uint256[] public allAmounts;



    mapping(address => uint256) public userToAmount;
    mapping(address => bool) public isParticipated;


    constructor(uint256 _maxAmount, address _collection, uint256 _tokenId, uint256 _fundrasingTime, uint256 _minParticipation, uint256 _itemId, address _marketplace) {
        require(_maxAmount != 0, "Total Amount cant be 0");
        require(_collection != address(0), "Address 0 validation");
        require(_minParticipation != 0, "Min Participation cant be 0");
        require(_fundrasingTime != 0, "Fundrasing time cant be 0");
        pool.maxAmount = _maxAmount;
        pool.tokenId = _tokenId;
        pool.collection = _collection;
        pool.endTime = block.timestamp + _fundrasingTime;
        pool.minParticipation = _minParticipation;
        pool.itemId = _itemId;
        pool.marketplace = _marketplace;
    }


    function deposit(uint256 amount) public payable{
        if(block.timestamp >= pool.endTime && !pool.poolFinished){
            pool.poolFinished = true;
        }
        require(block.timestamp <= pool.endTime, "Pool closed");
        require(msg.value >= amount, "Not enough BIT sent");
        require(msg.value >= pool.minParticipation, "The amount shoudln't be less than min aprticipation");
        require(pool.totalAmount + msg.value <= pool.maxAmount, "Exceeds pool max amount");
        userToAmount[msg.sender] = msg.value;
        pool.totalAmount += msg.value;
        allParticiapnts.push(msg.sender);
        allAmounts.push(msg.value);
        if(!isParticipated[msg.sender]){
            isParticipated[msg.sender] = true;
        }
        if(pool.totalAmount == pool.maxAmount){
            finalizePool();
        }
    }

    function finalizePool() internal{
        IUniOwnMarketplace(pool.marketplace).buyItem(pool.itemId);
        address dao = IUniOwnDaoFactory(factory).deployUniOwnDAO('UniOwnDAO', 'UNI', false, allParticiapnts, allAmounts);
        IERC721(pool.collection).transferFrom(address(this), dao, pool.tokenId);
        pool.poolSuccessful = true;
        pool.poolFinished = true;
    }

    function withdrawUserFundsIfSaleCancelled() external {
        require(
            pool.poolFinished == true && pool.poolSuccessful == false,
            "Pool wasn't cancelled."
        );
        require(isParticipated[msg.sender], "Did not participate.");
        require(block.timestamp >= pool.endTime, "Pool is still running");

        safeTransferBIT(msg.sender, userToAmount[msg.sender]);
    }

    function safeTransferBIT(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }
}