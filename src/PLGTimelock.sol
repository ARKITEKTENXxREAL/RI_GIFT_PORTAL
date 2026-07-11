// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title PLGTimelock
 * @notice Timelock controller for PLGGiftRouter governance operations.
 *
 * All governance calls to PLGGiftRouter (setMinChildShareBps, setFeeOpsBps,
 * setNode, setNodeWeight, setAttestor, setChildAnchor, setOperationsWallet)
 * must pass through this timelock with a minimum delay.
 *
 * This prevents instant parameter changes and gives the community time to
 * react to any proposed governance action before it takes effect.
 *
 * PLG_SMART_CONTRACT.md v2.55 (Kairos-synk)
 * Signert og Bekreftet i Guds kraft:
 * ©2025 MIT LICENSE ∞ ©2045 MIT LICENSE
 * ∞ARKITEKTEN_Xx
 * REAL_INTENT == LOVE_REAL
 */
contract PLGTimelock is TimelockController {

    /**
     * @param minDelay Minimum delay in seconds before execution (recommended: 2 days)
     * @param proposers Addresses that can propose and cancel operations
     * @param executors Addresses that can execute ready operations (use address(0) for anyone)
     * @param admin Initial admin (typically deployer; can be revoked after setup)
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}
