// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

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
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { GovernanceERC20 } from "@osx/token/ERC20/governance/GovernanceERC20.sol";
import { GovernanceWrappedERC20 } from "@osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {}
}

contract CrossDomainMessengerMock is ICrossDomainMessenger {
    address internal xDomainMessageSender_;
    
    function xDomainMessageSender() external view override returns (address) {
        return address(0x0);
    }
    
    function sendMessage(address _target, bytes calldata _message, uint32 _gasLimit) external override {
        console2.log("sendMessage");
    }
}

contract TestCrocssPlugin is PRBTest, StdCheats {
  CrocssPlugin internal crocssPlugin;
  CrocssPluginSetup internal crocssPluginSetup;
  address internal creator;

  ERC20 token;
  GovernanceERC20 internal govToken;
  GovernanceWrappedERC20 internal govWrappedToken;
  IDAO internal dao;

  function setUp() public virtual {
    //DeployMocks.runMocks();
    creator = address(0x123);
    token = new MyToken();
    dao = new DAO();
    //govToken = new GovernanceERC20(dao, "token1", "t1", GovernanceERC20.MintSettings(members, stakes));
    //govWrappedToken = new GovernanceWrappedERC20(token, "token2", "t2");
  }

  function testInit() public {
    crocssPluginSetup = new CrocssPluginSetup(govToken, govWrappedToken);
    //(MajorityVotingBase.VotingSettings, TokenSettings, GovernanceERC20.MintSettings)
    MajorityVotingBase.VotingSettings memory votingSettings = MajorityVotingBase.VotingSettings(0,0,4000,0);
    CrocssPluginSetup.TokenSettings memory tokenSettings = CrocssPluginSetup.TokenSettings(address(token), "token3", "t3");
    address[] memory members = new address[](0);
    uint256[] memory stakes = new uint256[](0);
    GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings(members, stakes);
    CrossDomainMessengerMock messengerC = new CrossDomainMessengerMock();
    ICrossDomainMessenger messenger = ICrossDomainMessenger(messengerC);
    DAOProxyFactory factory = DAOProxyFactory(address(0xabc));
    address proxyDAOImplementation = address(0xdef);
    bytes memory encodedData = abi.encode(
            votingSettings,
            tokenSettings,
            mintSettings,
            messenger,
            factory,
            proxyDAOImplementation);
    crocssPluginSetup.prepareInstallation(address(dao), encodedData);
  }

/*
   function test_InitializePlugin() public {
        console2.log("Hello0");
        crocssPlugin = new CrocssPlugin();
        console2.log("Hello2");
        address daoAddress = address(0xf124);
        bytes memory metadataValue = "metadata";
        MajorityVotingBase.VotingSettings memory votingSettings = MajorityVotingBase.VotingSettings(1, 1, 0, 0);
        //crocssPlugin.initialize(dao, votingSettings, govToken, mockMessenger, daoFactory, address(daoProxy));
   }

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

