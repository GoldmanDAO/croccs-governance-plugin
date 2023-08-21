// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import { PluginUUPSUpgradeable, IDAO } from "@osx/core/plugin/PluginUUPSUpgradeable.sol";

contract CrocssPlugin {
  function initializePlugin1(IDAO _dao) external initializer {
    __PluginUUPSUpgradeable_init(_dao);
  }
}

