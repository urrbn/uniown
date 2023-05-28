pragma solidity >=0.8.4;

import './UniOwnDAOtoken.sol';
import '../utils/NFTreceiver.sol';
import '../utils/ReentrancyGuard.sol';




contract UniOwnDAO is UniOwnDAOtoken, NFTreceiver, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewProposal(
        address indexed proposer, 
        uint256 indexed proposal, 
        ProposalType indexed proposalType, 
        string description, 
        address[] accounts, 
        uint256[] amounts, 
        bytes[] payloads
    );

    event ProposalCancelled(address indexed proposer, uint256 indexed proposal);

    event ProposalSponsored(address indexed sponsor, uint256 indexed proposal);
    
    event VoteCast(address indexed voter, uint256 indexed proposal, bool indexed approve);

    event ProposalProcessed(uint256 indexed proposal, bool indexed didProposalPass);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error Initialized();

    error PeriodBounds();

    error QuorumMax();

    error SupermajorityBounds();

    error InitCallFail();

    error TypeBounds();

    error NotProposer();

    error Sponsored();

    error NotMember();

    error NotCurrentProposal();

    error AlreadyVoted();

    error NotVoteable();

    error VotingNotEnded();

    error PrevNotProcessed();

    // error NotExtension();

    /*///////////////////////////////////////////////////////////////
                            DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    string public docs;

    uint256 private currentSponsoredProposal;
    
    uint256 public proposalCount;

    uint32 public votingPeriod;

    uint32 public gracePeriod;

    uint32 public quorum; // 1-100

    uint32 public supermajority; // 1-100
    
    bytes32 public constant VOTE_HASH = 
        keccak256('SignVote(address signer,uint256 proposal,bool approve)');
    


    mapping(uint256 => Proposal) public proposals;

    mapping(uint256 => ProposalState) public proposalStates;

    mapping(ProposalType => VoteType) public proposalVoteTypes;
    
    mapping(uint256 => mapping(address => bool)) public voted;

    mapping(address => uint256) public lastYesVote;

    enum ProposalType {
        CALL, // call contracts
        VPERIOD, // set `votingPeriod`
        GPERIOD, // set `gracePeriod`
        QUORUM, // set `quorum`
        SUPERMAJORITY, // set `supermajority`
        TYPE, // set `VoteType` to `ProposalType`
        PAUSE, // flip membership transferability
        ESCAPE
    }

    enum VoteType {
        SIMPLE_MAJORITY,
        SIMPLE_MAJORITY_QUORUM_REQUIRED,
        SUPERMAJORITY,
        SUPERMAJORITY_QUORUM_REQUIRED
    }

    struct Proposal {
        ProposalType proposalType;
        string description;
        address[] accounts; // member(s) being added/kicked; account(s) receiving payload
        uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
        bytes[] payloads; // data for CALL proposals
        uint256 prevProposal;
        uint96 yesVotes;
        uint96 noVotes;
        uint32 creationTime;
        address proposer;
    }

    struct ProposalState {
        bool passed;
        bool processed;
    }


    function init(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] calldata voters_,
        uint256[] calldata shares_
    ) public payable  virtual {


        if (votingPeriod != 0) revert Initialized();

        UniOwnDAOtoken._init(name_, symbol_, paused_, voters_, shares_);

        
        votingPeriod = 10 days;

        gracePeriod = 10 days;
        
        quorum = 80;
        
        supermajority = 51;

        // set initial vote types

        proposalVoteTypes[ProposalType.CALL] = VoteType(1);

        proposalVoteTypes[ProposalType.VPERIOD] = VoteType(1);

        proposalVoteTypes[ProposalType.GPERIOD] = VoteType(1);
        
        proposalVoteTypes[ProposalType.QUORUM] = VoteType(1);
        
        proposalVoteTypes[ProposalType.SUPERMAJORITY] = VoteType(1);

        proposalVoteTypes[ProposalType.TYPE] = VoteType(1);
        
        proposalVoteTypes[ProposalType.PAUSE] = VoteType(1);

        proposalVoteTypes[ProposalType.ESCAPE] = VoteType(1);

    }

    /*///////////////////////////////////////////////////////////////
                            PROPOSAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function getProposalArrays(uint256 proposal) public view virtual returns (
        address[] memory accounts, 
        uint256[] memory amounts, 
        bytes[] memory payloads
    ) {
        Proposal storage prop = proposals[proposal];
        
        (accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
    }

    function propose(
        ProposalType proposalType,
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    ) public payable nonReentrant virtual returns (uint256 proposal) {
        if (accounts.length != amounts.length || amounts.length != payloads.length) revert NoArrayParity();
        
        if (proposalType == ProposalType.VPERIOD) if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

        if (proposalType == ProposalType.GPERIOD) if (amounts[0] > 365 days) revert PeriodBounds();
        
        if (proposalType == ProposalType.QUORUM) if (amounts[0] > 100) revert QuorumMax();
        
        if (proposalType == ProposalType.SUPERMAJORITY) if (amounts[0] <= 51 || amounts[0] > 100) revert SupermajorityBounds();

        if (proposalType == ProposalType.TYPE) if (amounts[0] > 11 || amounts[1] > 3 || amounts.length != 2) revert TypeBounds();

        bool selfSponsor;

        // cannot realistically overflow on human timescales
        unchecked {
            proposalCount++;
        }

        proposal = proposalCount;

        proposals[proposal] = Proposal({
            proposalType: proposalType,
            description: description,
            accounts: accounts,
            amounts: amounts,
            payloads: payloads,
            prevProposal: selfSponsor ? currentSponsoredProposal : 0,
            yesVotes: 0,
            noVotes: 0,
            creationTime: _safeCastTo32(block.timestamp),
            proposer: msg.sender
        });

        if (selfSponsor) currentSponsoredProposal = proposal;

        emit NewProposal(msg.sender, proposal, proposalType, description, accounts, amounts, payloads);
    }

    function cancelProposal(uint256 proposal) public payable nonReentrant virtual {
        Proposal storage prop = proposals[proposal];

        if (msg.sender != prop.proposer) revert NotProposer();

        if (prop.creationTime != 0) revert Sponsored();

        delete proposals[proposal];

        emit ProposalCancelled(msg.sender, proposal);
    }

    function sponsorProposal(uint256 proposal) public payable nonReentrant virtual {
        Proposal storage prop = proposals[proposal];

        if (balanceOf[msg.sender] == 0) revert NotMember();

        if (prop.proposer == address(0)) revert NotCurrentProposal();

        if (prop.creationTime != 0) revert Sponsored();

        prop.prevProposal = currentSponsoredProposal;

        currentSponsoredProposal = proposal;

        prop.creationTime = _safeCastTo32(block.timestamp);

        emit ProposalSponsored(msg.sender, proposal);
    } 

    function vote(uint256 proposal, bool approve) public payable nonReentrant virtual {
        _vote(msg.sender, proposal, approve);
    }
    
    function voteBySig(
        address signer, 
        uint256 proposal, 
        bool approve, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public payable nonReentrant virtual {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            VOTE_HASH,
                            signer,
                            proposal,
                            approve
                        )
                    )
                )
            );
            
        address recoveredAddress = ecrecover(digest, v, r, s);

        if (recoveredAddress == address(0) || recoveredAddress != signer) revert InvalidSignature();
        
        _vote(signer, proposal, approve);
    }
    
    function _vote(
        address signer, 
        uint256 proposal, 
        bool approve
    ) internal virtual {
        Proposal storage prop = proposals[proposal];

        if (voted[proposal][signer]) revert AlreadyVoted();
        
        // this is safe from overflow because `votingPeriod` is capped so it will not combine
        // with unix time to exceed the max uint256 value
        // unchecked {
        //     if (block.timestamp > prop.creationTime + votingPeriod) revert NotVoteable();
        // }

        uint96 weight = getPriorVotes(signer, prop.creationTime);
        
        // this is safe from overflow because `yesVotes` and `noVotes` are capped by `totalSupply`
        // which is checked for overflow in `UniOwnDAOtoken` contract
        unchecked { 
            if (approve) {
                prop.yesVotes += weight;

                lastYesVote[signer] = proposal;
            } else {
                prop.noVotes += weight;
            }
        }
        
        voted[proposal][signer] = true;
        
        emit VoteCast(signer, proposal, approve);
    }

    function processProposal(uint256 proposal) public payable nonReentrant virtual returns (
        bool didProposalPass, bytes[] memory results
    ) {
        Proposal storage prop = proposals[proposal];

        VoteType voteType = proposalVoteTypes[prop.proposalType];

        if (prop.creationTime == 0) revert NotCurrentProposal();
        
        // this is safe from overflow because `votingPeriod` and `gracePeriod` are capped so they will not combine
        // with unix time to exceed the max uint256 value
        unchecked {
            if (block.timestamp <= prop.creationTime + votingPeriod + gracePeriod) revert VotingNotEnded();
        }

        // skip previous proposal processing requirement in case of escape hatch
        if (prop.proposalType != ProposalType.ESCAPE) 
            if (proposals[prop.prevProposal].creationTime != 0) revert PrevNotProcessed();

        didProposalPass = _countVotes(voteType, prop.yesVotes, prop.noVotes);
        
        if (didProposalPass) {
            // cannot realistically overflow on human timescales
            unchecked {
                    
                if (prop.proposalType == ProposalType.CALL) 
                    for (uint256 i; i < prop.accounts.length; i++) {
                        results = new bytes[](prop.accounts.length);
                        
                        (, bytes memory result) = prop.accounts[i].call{value: prop.amounts[i]}
                            (prop.payloads[i]);
                        
                        results[i] = result;
                    }
                    
                // governance settings
                if (prop.proposalType == ProposalType.VPERIOD) 
                    if (prop.amounts[0] != 0) votingPeriod = uint32(prop.amounts[0]);
                
                if (prop.proposalType == ProposalType.GPERIOD) 
                    if (prop.amounts[0] != 0) gracePeriod = uint32(prop.amounts[0]);
                
                if (prop.proposalType == ProposalType.QUORUM) 
                    if (prop.amounts[0] != 0) quorum = uint32(prop.amounts[0]);
                
                if (prop.proposalType == ProposalType.SUPERMAJORITY) 
                    if (prop.amounts[0] != 0) supermajority = uint32(prop.amounts[0]);
                
                if (prop.proposalType == ProposalType.TYPE) 
                    proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);
                
                if (prop.proposalType == ProposalType.PAUSE) 
                    _flipPause();
        
                
                if (prop.proposalType == ProposalType.ESCAPE)
                    delete proposals[prop.amounts[0]];

                
                proposalStates[proposal].passed = true;
            }
        }

        delete proposals[proposal];

        proposalStates[proposal].processed = true;

        emit ProposalProcessed(proposal, didProposalPass);
    }

    function _countVotes(
        VoteType voteType,
        uint256 yesVotes,
        uint256 noVotes
    ) internal view virtual returns (bool didProposalPass) {
        // fail proposal if no participation
        if (yesVotes == 0 && noVotes == 0) return false;

        // rule out any failed quorums
        if (voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            uint256 minVotes = (totalSupply * quorum) / 100;
            
            // this is safe from overflow because `yesVotes` and `noVotes` 
            // supply are checked in `UniOwnDAOtoken` contract
            unchecked {
                uint256 votes = yesVotes + noVotes;

                if (votes < minVotes) return false;
            }
        }
        
        // simple majority check
        if (voteType == VoteType.SIMPLE_MAJORITY || voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED) {
            if (yesVotes > noVotes) return true;
        // supermajority check
        } else {
            // example: 7 yes, 2 no, supermajority = 66
            // ((7+2) * 66) / 100 = 5.94; 7 yes will pass
            uint256 minYes = ((yesVotes + noVotes) * supermajority) / 100;

            if (yesVotes >= minYes) return true;
        }
    }

    receive() external payable virtual {}
}