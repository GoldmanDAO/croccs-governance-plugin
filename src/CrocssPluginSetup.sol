// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { PermissionLib } from "@osx/core/permission/PermissionLib.sol";
import { PluginSetup, IPluginSetup } from "@osx/framework/plugin/setup/PluginSetup.sol";
import { CrocssPlugin } from "./CrocssPlugin.sol";

/// @title CrocssPluginSetup build 1
contract SimpleStorageBuild1Setup is PluginSetup {
  address private immutable crocssPluginImplementation;

  constructor() {
    simpleStorageImplementation = address(new SimpleStorageBuild1());
  }

  /// @inheritdoc IPluginSetup
  function prepareInstallation(
    address _dao,
    bytes memory _data
  ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
    uint256 number = abi.decode(_data, (uint256));

    plugin = createERC1967Proxy(
      simpleStorageImplementation,
      abi.encodeWithSelector(SimpleStorageBuild1.initializeBuild1.selector, _dao, number)
    );

    PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](1);

    permissions[0] = PermissionLib.MultiTargetPermission({
      operation: PermissionLib.Operation.Grant,
      where: plugin,
      who: _dao,
      condition: PermissionLib.NO_CONDITION,
      permissionId: SimpleStorageBuild1(this.implementation()).STORE_PERMISSION_ID()
    });

    preparedSetupData.permissions = permissions;
  }

  /// @inheritdoc IPluginSetup
  function prepareUninstallation(
    address _dao,
    SetupPayload calldata _payload
  ) external view returns (PermissionLib.MultiTargetPermission[] memory permissions) {
    permissions = new PermissionLib.MultiTargetPermission[](1);

    permissions[0] = PermissionLib.MultiTargetPermission({
      operation: PermissionLib.Operation.Revoke,
      where: _payload.plugin,
      who: _dao,
      condition: PermissionLib.NO_CONDITION,
      permissionId: SimpleStorageBuild1(this.implementation()).STORE_PERMISSION_ID()
    });
  }

  /// @inheritdoc IPluginSetup
  function implementation() external view returns (address) {
    return simpleStorageImplementation;
  }
}
