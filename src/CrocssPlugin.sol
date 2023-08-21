// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import { PluginUUPSUpgradeable, IDAO } from "@osx/core/plugin/PluginUUPSUpgradeable.sol";

contract CrocssPlugin {
  function id(uint256 value) external pure returns (uint256) {
    return value;
  }
}

