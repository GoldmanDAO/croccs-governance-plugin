// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IL2CrossDomainMessenger } from "src/interfaces/IL2CrossDomainMessenger.sol";
import { IMajorityVoting } from "src/IMajorityVoting.sol";
import { hasBit, flipBit } from "@osx/core/utils/BitMap.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { CrocssPlugin } from "src/CrocssPlugin.sol";

contract DAOProxy is Initializable, ReentrancyGuard {
  struct Action {
    address to;
    uint256 value;
    bytes data;
  }
  struct Tally {
    uint256 abstain;
    uint256 yes;
    uint256 no;
  }

  struct L2Proposal {
    uint256 proposalId;
    uint64 endDate;
    bytes32 merkleRoot;
    Tally tally;
    mapping(address => IMajorityVoting.VoteOption) voters;
  }

  /// @notice Thrown if the action array length is larger than `MAX_ACTIONS`.
  error TooManyActions();

  /// @notice Thrown if action execution has failed.
  /// @param index The index of the action in the action array that failed.
  error ActionFailed(uint256 index);

  /// @notice Thrown if an action has insufficent gas left.
  error InsufficientGas();

  error ProposalAlreadyExists(uint256 proposalId);

  error AddressAlreadyVoted(address account);
  error AddressAmountNotInTree(address account, uint256 amount);
  error ProposalIsFinished(uint256 proposalId);
  error ProposalNotFinished(uint256 proposalId);

  uint256 internal constant MAX_ACTIONS = 256;

  IL2CrossDomainMessenger public bridge;
  address public parentDAO;
  CrocssPlugin public parentDAOPlugin;
  mapping(uint256 => L2Proposal) proposals;

  event Executed(Action[] actions, uint256 allowFailureMap, uint256 failureMap, bytes[] execResults);
  /// @notice Emitted when a vote is cast by a voter.
  /// @param proposalId The ID of the proposal.
  /// @param voter The voter casting the vote.
  /// @param voteOption The casted vote option.
  /// @param votingPower The voting power behind this vote.
  event VoteCast(
    uint256 indexed proposalId,
    address indexed voter,
    IMajorityVoting.VoteOption voteOption,
    uint256 votingPower
  );

  event ProposalCreated(uint256 indexed proposalId, uint64 endDate, bytes32 merkleRoot);
  event ResultsBridged(uint256 indexed proposalId, uint8 winnerOption);

  modifier onlyParentDAO() {
    require(msg.sender == address(bridge) && bridge.xDomainMessageSender() == parentDAO, "Not parent DAO");
    _;
  }

  function initialize(
    IL2CrossDomainMessenger _bridge,
    address _parentDAO,
    address _parentDAOPlugin
  ) public initializer {
    bridge = _bridge;
    parentDAO = _parentDAO;
    parentDAOPlugin = CrocssPlugin(_parentDAOPlugin);
  }

  function createProposal(uint256 _proposalId, uint64 _endDate, bytes32 _merkleRoot) external onlyParentDAO {
    if (proposals[_proposalId].proposalId == _proposalId) {
      revert ProposalAlreadyExists(_proposalId);
    }

    L2Proposal storage proposal = proposals[_proposalId];
    proposal.proposalId = _proposalId;
    proposal.endDate = _endDate;
    proposal.merkleRoot = _merkleRoot;

    emit ProposalCreated(_proposalId, _endDate, _merkleRoot);
  }

  function vote(
    uint256 _proposalId,
    IMajorityVoting.VoteOption _voteOption,
    bytes32[] memory _proof,
    address _addr,
    uint256 _amount
  ) public virtual {
    L2Proposal storage proposal = proposals[_proposalId];

    bytes32 memberHash = keccak256(abi.encodePacked(_addr, _amount));
    bool proof = MerkleProof.verify(_proof, proposal.merkleRoot, memberHash);

    if (proof == false) {
      revert AddressAmountNotInTree(_addr, _amount);
    }

    // Check if proposal still open
    if (proposal.endDate > block.number) {
      revert ProposalIsFinished(_proposalId);
    }

    IMajorityVoting.VoteOption state = proposal.voters[_addr];

    // If voter had previously voted, decrease count
    if (state == IMajorityVoting.VoteOption.Yes) {
      proposal.tally.yes = proposal.tally.yes - _amount;
    } else if (state == IMajorityVoting.VoteOption.No) {
      proposal.tally.no = proposal.tally.no - _amount;
    } else if (state == IMajorityVoting.VoteOption.Abstain) {
      proposal.tally.abstain = proposal.tally.abstain - _amount;
    }

    // write the updated/new vote for the voter.
    if (_voteOption == IMajorityVoting.VoteOption.Yes) {
      proposal.tally.yes = proposal.tally.yes + _amount;
    } else if (_voteOption == IMajorityVoting.VoteOption.No) {
      proposal.tally.no = proposal.tally.no + _amount;
    } else if (_voteOption == IMajorityVoting.VoteOption.Abstain) {
      proposal.tally.abstain = proposal.tally.abstain + _amount;
    }

    proposal.voters[_addr] = _voteOption;
    emit VoteCast({ proposalId: _proposalId, voter: _addr, voteOption: _voteOption, votingPower: _amount });
  }

  function relyResults(uint256 _proposalId) external {
    L2Proposal storage proposal = proposals[_proposalId];
    // Check the proposal ending is in time
    if (proposal.endDate > block.number) {
      revert ProposalNotFinished(_proposalId);
    }
    // Tecnically you could try relying it again, but it's controlled in the L1

    // Get the results
    uint8 winnerOption = 0;
    if (proposal.tally.yes > proposal.tally.no && proposal.tally.yes > proposal.tally.abstain) {
      winnerOption = 1;
    } else if (proposal.tally.no > proposal.tally.abstain) {
      winnerOption = 2;
    } else {
      winnerOption = 0;
    }

    // Get the Messaging Bridge
    // Send the results over
    bridge.sendMessage(
      address(parentDAOPlugin),
      abi.encodePacked(parentDAOPlugin.executeProposal.selector, _proposalId, winnerOption),
      0
    );
    // Emit an event of results bridged
    emit ResultsBridged(_proposalId, winnerOption);
  }

  function execute(Action[] calldata _actions, uint256 _allowFailureMap) external onlyParentDAO nonReentrant {
    if (_actions.length > MAX_ACTIONS) revert TooManyActions();

    bytes[] memory execResults = new bytes[](_actions.length);
    uint256 failureMap = 0;

    uint256 gasBefore;
    uint256 gasAfter;

    for (uint256 i = 0; i < _actions.length; ) {
      gasBefore = gasleft();

      (bool success, bytes memory result) = _actions[i].to.call{ value: _actions[i].value }(_actions[i].data);
      gasAfter = gasleft();

      // Check if failure is allowed
      if (!hasBit(_allowFailureMap, uint8(i))) {
        // Check if the call failed.
        if (!success) revert ActionFailed(i);
      } else {
        // Check if the call failed.
        if (!success) {
          // Make sure that the action call did not fail because 63/64 of `gasleft()` was
          // insufficient to execute the external call `.to.call` (see
          // [ERC-150](https://eips.ethereum.org/EIPS/eip-150)).
          // In specific scenarios, i.e. proposal execution where the last action in the action
          // array is allowed to fail, the account calling `execute` could force-fail this action by
          // setting a gas limit
          // where 63/64 is insufficient causing the `.to.call` to fail, but where the remaining
          // 1/64 gas are sufficient to successfully finish the `execute` call.
          if (gasAfter < gasBefore / 64) revert InsufficientGas();

          // Store that this action failed.
          failureMap = flipBit(failureMap, uint8(i));
        }
      }

      execResults[i] = result;

      unchecked {
        ++i;
      }
    }

    emit Executed({
      actions: _actions,
      allowFailureMap: _allowFailureMap,
      failureMap: failureMap,
      execResults: execResults
    });
  }
}
