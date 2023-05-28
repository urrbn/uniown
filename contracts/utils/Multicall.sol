abstract contract Multicall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                if (result.length < 68) revert();
                    
                assembly {
                    result := add(result, 0x04)
                }
                    
                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }
}