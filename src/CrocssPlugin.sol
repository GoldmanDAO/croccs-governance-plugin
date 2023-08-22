// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import { MajorityVotingBase } from "@osx/plugins/governance/majority-voting/MajorityVotingBase.sol";
import { IMembership } from "@osx/core/plugin/membership/IMembership.sol";
import { IDAO } from "@osx/core/dao/IDAO.sol";
import { IVotesUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { RATIO_BASE, _applyRatioCeiled } from "@osx/plugins/utils/Ratio.sol";

contract CrocssPlugin is IMembership, MajorityVotingBase {
  /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
  bytes4 internal constant TOKEN_VOTING_INTERFACE_ID = this.initialize.selector ^ this.getVotingToken.selector;

  /// @notice An [OpenZeppelin `Votes`](https://docs.openzeppelin.com/contracts/4.x/api/governance#Votes) compatible contract referencing the token being used for voting.
  IVotesUpgradeable private votingToken;

  /// @notice Thrown if the voting power is zero
  error NoVotingPower();

  function initialize(
    IDAO _dao,
    VotingSettings calldata _votingSettings,
    IVotesUpgradeable _token
  ) external initializer {
    __MajorityVotingBase_init(_dao, _votingSettings);

    votingToken = _token;

    emit MembershipContractAnnounced({ definingContract: address(_token) });
  }

  /// @notice Checks if this or the parent contract supports an interface by its ID.
  /// @param _interfaceId The ID of the interface.
  /// @return Returns `true` if the interface is supported.
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == TOKEN_VOTING_INTERFACE_ID ||
      _interfaceId == type(IMembership).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /// @notice getter function for the voting token.
  /// @dev public function also useful for registering interfaceId and for distinguishing from majority voting interface.
  /// @return The token used for voting.
  function getVotingToken() public view returns (IVotesUpgradeable) {
    return votingToken;
  }

  /// @inheritdoc MajorityVotingBase
  function totalVotingPower(uint256 _blockNumber) public view override returns (uint256) {
    return votingToken.getPastTotalSupply(_blockNumber);
  }

  /// @inheritdoc IMembership
  function isMember(address _account) external view returns (bool) {
    // A member must own at least one token or have at least one token delegated to her/him.
    return votingToken.getVotes(_account) > 0 || IERC20Upgradeable(address(votingToken)).balanceOf(_account) > 0;
  }

  /// @inheritdoc MajorityVotingBase
  function _canVote(
    uint256 _proposalId,
    address _account,
    VoteOption _voteOption
  ) internal view override returns (bool) {
    Proposal storage proposal_ = proposals[_proposalId];

    // The proposal vote hasn't started or has already ended.
    if (!_isProposalOpen(proposal_)) {
      return false;
    }

    // The voter votes `None` which is not allowed.
    if (_voteOption == VoteOption.None) {
      return false;
    }

    // The voter has no voting power.
    if (votingToken.getPastVotes(_account, proposal_.parameters.snapshotBlock) == 0) {
      return false;
    }

    // The voter has already voted but vote replacment is not allowed.
    if (
      proposal_.voters[_account] != VoteOption.None && proposal_.parameters.votingMode != VotingMode.VoteReplacement
    ) {
      return false;
    }

    return true;
  }

  /// @inheritdoc MajorityVotingBase
  function createProposal(
    bytes calldata _metadata,
    IDAO.Action[] calldata _actions,
    uint256 _allowFailureMap,
    uint64 _startDate,
    uint64 _endDate,
    VoteOption _voteOption,
    bool _tryEarlyExecution
  ) external override returns (uint256 proposalId) {}

  function createProposal(
    bytes calldata _metadata,
    IDAO.Action[] calldata _actions,
    uint256 _allowFailureMap,
    uint64 _startDate,
    uint64 _endDate
  ) external returns (uint256 proposalId) {
    // Check that either `_msgSender` owns enough tokens or has enough voting power from being a delegatee.
    {
      uint256 minProposerVotingPower_ = minProposerVotingPower();

      if (minProposerVotingPower_ != 0) {
        // Because of the checks in `TokenVotingSetup`, we can assume that `votingToken` is an [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token.
        if (
          votingToken.getVotes(_msgSender()) < minProposerVotingPower_ &&
          IERC20Upgradeable(address(votingToken)).balanceOf(_msgSender()) < minProposerVotingPower_
        ) {
          revert ProposalCreationForbidden(_msgSender());
        }
      }
    }

    uint256 snapshotBlock;
    unchecked {
      snapshotBlock = block.number - 1; // The snapshot block must be mined already to protect the transaction against backrunning transactions causing census changes.
    }

    uint256 totalVotingPower_ = totalVotingPower(snapshotBlock);

    if (totalVotingPower_ == 0) {
      revert NoVotingPower();
    }

    (_startDate, _endDate) = _validateProposalDates(_startDate, _endDate);

    proposalId = _createProposal({
      _creator: _msgSender(),
      _metadata: _metadata,
      _startDate: _startDate,
      _endDate: _endDate,
      _actions: _actions,
      _allowFailureMap: _allowFailureMap
    });

    // Store proposal related information
    Proposal storage proposal_ = proposals[proposalId];

    proposal_.parameters.startDate = _startDate;
    proposal_.parameters.endDate = _endDate;
    proposal_.parameters.snapshotBlock = uint64(snapshotBlock);
    proposal_.parameters.votingMode = votingMode();
    proposal_.parameters.supportThreshold = supportThreshold();
    proposal_.parameters.minVotingPower = _applyRatioCeiled(totalVotingPower_, minParticipation());

    // Reduce costs
    if (_allowFailureMap != 0) {
      proposal_.allowFailureMap = _allowFailureMap;
    }

    for (uint256 i; i < _actions.length; ) {
      proposal_.actions.push(_actions[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _vote(uint256 _proposalId, VoteOption _voteOption, address _voter) internal {}

  /// @inheritdoc MajorityVotingBase
  function _vote(
    uint256 _proposalId,
    VoteOption _voteOption,
    address _voter,
    bool _tryEarlyExecution
  ) internal override {}

  /// @dev This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint256[49] private __gap;
}
