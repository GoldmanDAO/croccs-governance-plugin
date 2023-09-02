// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Deploy } from "../script/Deploy.s.sol";
import { DeployMocks } from "../script/DeployMocks.s.sol";

import { MajorityVotingBase } from "../src/MajorityVotingBase.sol";
import { IVotesUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import { ICrossDomainMessenger } from "src/interfaces/ICrossDomainMessenger.sol";
import { DAOProxyFactory } from "src/DAOProxyFactory.sol";
import { CrocssPlugin, IDAO } from "../src/CrocssPlugin.sol";
import { CrocssPluginSetup } from "../src/CrocssPluginSetup.sol";

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { GovernanceERC20 } from "@osx/token/ERC20/governance/GovernanceERC20.sol";
import { GovernanceWrappedERC20 } from "@osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract TestCrocssPlugin is Deploy, DeployMocks {
  CrocssPlugin internal crocssPlugin;
  CrocssPluginSetup internal crocssPluginSetup;
  address internal creator;

  IERC20 internal token;
  GovernanceERC20 internal govToken;
  IDAO internal dao;

  function setUp() public virtual {
    console2.log("Hello-0");
    DeployMocks.runMocks();
    token = IERC20(address(0xe123));
    dao = IDAO(address(0xf124));
    console2.log("Hello0");
    address[] memory members = new address[](0);
    uint256[] memory stakes = new uint256[](0);
    console2.log("Hello");
    govToken = new GovernanceERC20(dao, "token1", "t1", GovernanceERC20.MintSettings(members, stakes));
    console2.log("Hello2");
    crocssPlugin = new CrocssPlugin();
    console2.log("Hello0");
    creator = address(0x123);
  }

  // function test_InitializePlugin() external {
  // address daoAddress = address(0xf124);
  // bytes memory metadataValue = "metadata";
  // MajorityVotingBase.VotingSettings memory votingSettings = MajorityVotingBase.VotingSettings(1, 1, 0, 0);
  // crocssPlugin.initialize(dao, votingSettings, govToken, mockMessenger, daoFactory, address(daoProxy));
  // }

  /*
    function testInitialize() public {
        MajorityVotingBase.VotingSettings memory votingSettings = MajorityVotingBase.VotingSettings(0,0,0,0);
        IVotesUpgradeable token = IVotesUpgradeable(address(0x456));
        ICrossDomainMessenger messenger = ICrossDomainMessenger(address(0x789));
        DAOProxyFactory factory = DAOProxyFactory(address(0xabc));
        address proxyDAOImplementation = address(0xdef);
        crocssPlugin.initialize(
            dao,
            votingSettings,
            token,
            messenger,
            factory,
            proxyDAOImplementation
        );
    }

    function testCreateProposal() public {
        // Define proposal parameters
        string memory metadataValue = "Proposal metadata";
        uint64 startDate = uint64(block.timestamp);
        uint64 endDate = uint64(block.timestamp + 86400); // 1 day from now
        IDAO.Action[] memory actions = new IDAO.Action[](1);
        actions[0] = IDAO.Action(
            address(0x457),
            0,
            ""
        );
        uint256 allowFailureMap = 0;
        uint256 blockNumber = block.number;
        bytes32 hash = bytes32("hash");

        // Call createProposal function
        uint256 proposalId = crocssPlugin.createProposal(
            bytes(metadataValue),
            actions,
            allowFailureMap,
            startDate,
            endDate,
            blockNumber,
            hash
        );

        // Assert that proposal parameters were set correctly
        assertEq(proposalId, 1, "Proposal ID should be 1");
    }
    */
}

