// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IUniOwnDaoFactory {
    function deployUniOwnDAO(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] calldata voters_,
        uint256[] calldata shares_
    ) external  returns (address);
}