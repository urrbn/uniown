
pragma solidity >=0.8.4;

import './UniOwnDAO.sol';
import "@openzeppelin/contracts/proxy/Clones.sol";



/// @notice Factory to deploy UniOwn DAO.
contract UniOwnDaoFactory  {
    event DAOdeployed(
        address dao, 
        string name, 
        string symbol, 
        bool paused, 
        address[] voters,
        uint256[] shares
    );

    address public immutable uniOwnMaster;


    constructor(address uniOwnMaster_) {
        uniOwnMaster = uniOwnMaster_;
    }
    
    function deployUniOwnDAO(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] calldata voters_,
        uint256[] calldata shares_
    ) public returns(address) {
        address clone = Clones.clone(uniOwnMaster);
      
        UniOwnDAO(payable(clone)).init(
            name_, 
            symbol_, 
            paused_, 
            voters_, 
            shares_  
        );

        emit DAOdeployed(clone, name_, symbol_, paused_, voters_, shares_);
        return clone;
    }


}