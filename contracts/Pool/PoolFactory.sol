// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./UniOwnPool.sol";


contract UniOwnPoolFactory{

    address[] public allPools;
    address public marketplace = 0xBAdea772bD5F1B8b0271560160DD0f62cBc051c9;


    function deployPool(
        uint256 _maxAmount, 
        address _collection, 
        uint256 _tokenId, 
        uint256 _fundrasingTime, 
        uint256 _minParticipation, 
        uint256 _itemId) 
        public {
        UniOwnPool pool = new UniOwnPool(
            _maxAmount,
            _collection,
            _tokenId,
            _fundrasingTime,
            _minParticipation,
            _itemId,
            marketplace
        );
        allPools.push(address(pool));
    }

    // Function to get all airdrops
    function getAllPools(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (address[] memory)
    {
        require(endIndex > startIndex, "Bad input");
        require(endIndex <= allPools.length, "access out of rage");

        address[] memory pools = new address[](endIndex - startIndex);
        uint256 index = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            pools[index] = allPools[i];
            index++;
        }

        return pools;
    }

    // Function to return number of pools deployed
    function getNumberOfPoolsDeployed() external view returns (uint256) {
        return allPools.length;
    }

}