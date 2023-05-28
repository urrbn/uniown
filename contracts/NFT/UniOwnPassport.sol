// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UniOwnPassport is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10000; // Maximum token supply
    uint256 private _currentTokenId = 0; // Counter for token IDs

    constructor() ERC721("UniOwnPassport", "PASS") {}

    function mint(address to) public onlyOwner {
        require(_currentTokenId < MAX_SUPPLY, "UniOwnPassport: Max supply reached");
        _mint(to, _currentTokenId);
        _currentTokenId++;
    }

    function burn(uint256 tokenId) public  {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function currentTokenId() public view returns (uint256) {
        return _currentTokenId;
    }

    // function buildMetadata(uint256 _tokenId)
    //     private
    //     view
    //     returns (string memory)
    // {
    //     return
    //         string(
    //             abi.encodePacked(
    //                 "data:application/json;base64,",
    //                 Base64.encode(
    //                     bytes(
    //                         abi.encodePacked(
    //                             '{"name":"Dynamic NFT", "description":"Dynamic NFT Test","image": "https://gateway.pinata.cloud/ipfs/QmeAKDXvQyGUdvwRSvazCyj4CYeN6qrcpQr4Lmgf7Cc2UC", "attributes": ',
    //                             "[",
    //                             '{"trait_type": "Temperature",',
    //                             '"value":"',
    //                             Strings.toString(temperature),
    //                             '"}',
    //                             "]",
    //                             "}"
    //                         )
    //                     )
    //                 )
    //             )
    //         );
    // }

    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     virtual
    //     override(ERC721)
    //     returns (string memory)
    // {
    // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
     
    //     return buildMetadata(tokenId);
    // }
}

