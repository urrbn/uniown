// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract UniOwnPass is ERC721, Ownable {

    using Counters for Counters.Counter;

    uint256 public totalDividends = 5;
    bytes32 private jobId;
    uint256 public totalSpent = 6;
    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) ownerToTokenId;
    mapping(uint256 => address) tokenIdToOwner;

    
    constructor() ERC721("UniOwn Passport", "UNI") {}
    
    
    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"UniOwn Passport", "description":"Your virtual identity","image": "https://gateway.pinata.cloud/ipfs/QmeAKDXvQyGUdvwRSvazCyj4CYeN6qrcpQr4Lmgf7Cc2UC", "totalDividends": "', 
                                Strings.toString(totalDividends),
                                '", "totalSpent": "',
                                Strings.toString(totalSpent),
                                '"}'
                            )
                        )
                    )
                )
            );
    }


    //ERC721 functions
    function safeMint(uint minttimes) external payable {
     
        for(uint i=0;i<minttimes;i++){
           _safeMint(msg.sender, _tokenIdCounter.current()); 
           _tokenIdCounter.increment();
        }            
   
  
    }
 
    function tokenURI(uint256 tokenId)
       public
       view
       virtual
       override(ERC721)
       returns (string memory)
    {
       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
     
       return buildMetadata(tokenId);
    }
 
    //Return current counter value
    function getCounter() external view returns (uint256)
    {
        return _tokenIdCounter.current();
    }
 
}

