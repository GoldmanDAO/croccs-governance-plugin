// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";

import { Deploy } from "../script/Deploy.s.sol";
import { DeployMocks } from "../script/DeployMocks.s.sol";

import { MajorityVotingBase } from "../src/MajorityVotingBase.sol";
import { IVotesUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import { ICrossDomainMessenger } from "src/interfaces/ICrossDomainMessenger.sol";
import { DAOProxyFactory } from "src/DAOProxyFactory.sol";
import { CrocssPlugin, IDAO } from "../src/CrocssPlugin.sol";
import { CrocssPluginSetup } from "../src/CrocssPluginSetup.sol";
import { DAO } from "@osx/core/dao/DAO.sol";

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { GovernanceERC20 } from "@osx/token/ERC20/governance/GovernanceERC20.sol";
import { GovernanceWrappedERC20 } from "@osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

import { MockL2CrossDomainMessenger } from "./mocks/MockL2CrossDomainMessenger.sol";

contract TestCrocssPlugin is PRBTest, StdCheats {
    address internal creator;

    CrocssPlugin internal crocssPlugin;
    CrocssPluginSetup internal crocssPluginSetup;
    DAOProxyFactory internal factory;
    address internal proxyDAOImplementation;

    IDAO internal dao;
    GovernanceERC20 internal govToken;
    GovernanceWrappedERC20 internal govWrappedToken;
    GovernanceERC20.MintSettings internal mintSettings;
    MajorityVotingBase.VotingSettings internal votingSettings;
    CrocssPluginSetup.TokenSettings internal tokenSettings;

    MockL2CrossDomainMessenger internal messenger;

    function setUp() public virtual {
        creator = address(0x123);
        dao = new DAO();
        address[] memory members = new address[](1);
        members[0] = creator;
        uint256[] memory stakes = new uint256[](1);
        stakes[0] = 100;
        mintSettings = GovernanceERC20.MintSettings(members, stakes);
        govToken = new GovernanceERC20(dao, "token1", "t1", GovernanceERC20.MintSettings(members, stakes));
        govWrappedToken = new GovernanceWrappedERC20(govToken, "token2", "t2");
        votingSettings = MajorityVotingBase.VotingSettings(0, 0, 4000, 0);
        tokenSettings = CrocssPluginSetup.TokenSettings(address(govToken), "token3", "t3");
        messenger = new MockL2CrossDomainMessenger();
        factory = DAOProxyFactory(address(0xabc));
        proxyDAOImplementation = address(0xdef);
    }

    function testCrocssPluginSetup() public {
        crocssPluginSetup = new CrocssPluginSetup(govToken, govWrappedToken);
        bytes memory encodedData =
            abi.encode(votingSettings, tokenSettings, mintSettings, messenger, factory, proxyDAOImplementation);
        (address pluginAddress,) = crocssPluginSetup.prepareInstallation(address(dao), encodedData);
        address implementationAddress = crocssPluginSetup.implementation();
        assertEq(implementationAddress, address(0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c), "Wrong implementation address");
        crocssPlugin = CrocssPlugin(pluginAddress);
        assertEq(address(crocssPlugin), address(0x746326d3E4e54BA617F8aB39A21b7420aE8bF97d), "Wrong plugin address");
        assertEq(address(crocssPlugin.getVotingToken()), address(0x2e234DAe75C793f67A35089C9d99245E1C58470b), "Wrong voting token address");
        vm.roll(20);
        assertEq(crocssPlugin.totalVotingPower(block.number - 1), 100, "Wrong voting power");
        assertEq(govToken.balanceOf(creator), 100, "Wrong ");
    }

    function testCreateProposal() public {
        crocssPluginSetup = new CrocssPluginSetup(govToken, govWrappedToken);
        bytes memory encodedData =
            abi.encode(votingSettings, tokenSettings, mintSettings, messenger, factory, proxyDAOImplementation);
        (address pluginAddress,) = crocssPluginSetup.prepareInstallation(address(dao), encodedData);
        crocssPlugin = CrocssPlugin(pluginAddress);
        vm.roll(20);

        uint256 proposalId = crocssPlugin.createProposal(
            "metadata",
            new IDAO.Action[](0),
            0,
            uint64(block.timestamp),
            uint64(block.timestamp + 86400),
            block.number + 10,
            bytes32("hash")
        );
        assertEq(proposalId, 0, "Wrong proposal id");

        uint256 proposalId1 = crocssPlugin.createProposal(
            "metadata",
            new IDAO.Action[](0),
            0,
            uint64(block.timestamp),
            uint64(block.timestamp + 86400),
            block.number + 10,
            bytes32("hash")
        );
        assertEq(proposalId1, 1, "Wrong proposal id");

        crocssPlugin.bridgeProposal(proposalId);
    }

}
