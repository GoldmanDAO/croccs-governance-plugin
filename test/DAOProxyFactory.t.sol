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
import { DAOProxy } from "src/DAOProxy.sol";
import { DAOProxyFactory } from "src/DAOProxyFactory.sol";
import { CrocssPlugin, IDAO } from "../src/CrocssPlugin.sol";
import { CrocssPluginSetup } from "../src/CrocssPluginSetup.sol";
import { DAO } from "@osx/core/dao/DAO.sol";

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { GovernanceERC20 } from "@osx/token/ERC20/governance/GovernanceERC20.sol";
import { GovernanceWrappedERC20 } from "@osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract TestDAOProxyFactory is PRBTest, StdCheats {
    address internal creator;

    DAOProxy internal daoProxy;
    DAOProxyFactory internal daoProxyFactory;
    CrocssPlugin internal crocssPlugin;
    CrocssPluginSetup internal crocssPluginSetup;

    GovernanceERC20 internal govToken;
    GovernanceWrappedERC20 internal govWrappedToken;
    IDAO internal dao;
    GovernanceERC20.MintSettings internal mintSettings;

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
    }


}

