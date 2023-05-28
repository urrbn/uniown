// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.12;

interface IUniOwnMarketplace {
    function buyItem(uint256 id) external payable;
}