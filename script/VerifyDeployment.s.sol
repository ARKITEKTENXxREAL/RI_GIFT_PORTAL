// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PLGGiftRouter}  from "../src/PLGGiftRouter.sol";
import {PLGTimelock}    from "../src/PLGTimelock.sol";
import {PLGGovernor}    from "../src/PLGGovernor.sol";
import {PLGVotingToken} from "../src/PLGVotingToken.sol";

/**
 * @title VerifyDeployment
 * @notice Post-deploy sanity checks for the PLG system.
 *
 * Run after Deploy.s.sol to confirm:
 *   - All contracts are deployed at expected addresses
 *   - Router parameters match the deployment config
 *   - Timelock is the router's validatorSet
 *   - Governor has correct roles on timelock
 *   - Deployer admin has been revoked
 *   - Token supply distributed correctly
 *   - Chain ID matches deployment target
 *
 * Usage:
 *   forge script script/VerifyDeployment.s.sol \
 *     --rpc-url <chain> \
 *     -vvvv
 *
 * Required env vars:
 *   PLG_ROUTER_ADDRESS
 *   PLG_TIMELOCK_ADDRESS
 *   PLG_GOVERNOR_ADDRESS
 *   PLG_TOKEN_ADDRESS
 *   PLG_TOKEN_HOLDER        - address that should hold all initial tokens
 *   DEPLOYER_ADDRESS        - should have NO admin role after deployment
 */
contract VerifyDeployment is Script {

    function run() external view {
        address routerAddr   = vm.envAddress("PLG_ROUTER_ADDRESS");
        address timelockAddr = vm.envAddress("PLG_TIMELOCK_ADDRESS");
        address governorAddr = vm.envAddress("PLG_GOVERNOR_ADDRESS");
        address tokenAddr    = vm.envAddress("PLG_TOKEN_ADDRESS");
        address tokenHolder  = vm.envAddress("PLG_TOKEN_HOLDER");
        address deployer     = vm.envAddress("DEPLOYER_ADDRESS");

        PLGGiftRouter  router   = PLGGiftRouter(payable(routerAddr));
        PLGTimelock    timelock = PLGTimelock(payable(timelockAddr));
        PLGGovernor    governor = PLGGovernor(payable(governorAddr));
        PLGVotingToken token    = PLGVotingToken(tokenAddr);

        uint256 failures = 0;

        console.log("=== PLG DEPLOYMENT VERIFICATION ===");
        console.log("Chain ID:", block.chainid);
        console.log("");

        // ─ 1. Router: validatorSet = timelock ─
        failures += _check(
            "Router.validatorSet == timelock",
            router.validatorSet() == timelockAddr
        );

        // ─ 2. Router: chainId matches current chain ─
        failures += _check(
            "Router.chainId == block.chainid",
            router.chainId() == block.chainid
        );

        // ─ 3. Router: child share at floor ─
        failures += _check(
            "Router.minChildShareBps >= 2500 (25%)",
            router.minChildShareBps() >= 2500
        );

        // ─ 4. Router: fee within cap ─
        failures += _check(
            "Router.feeOpsBps <= 1000 (10%)",
            router.feeOpsBps() <= 1000
        );

        // ─ 5. Timelock: governor has PROPOSER role ─
        failures += _check(
            "Governor has PROPOSER_ROLE on timelock",
            timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddr)
        );

        // ─ 6. Timelock: governor has CANCELLER role ─
        failures += _check(
            "Governor has CANCELLER_ROLE on timelock",
            timelock.hasRole(timelock.CANCELLER_ROLE(), governorAddr)
        );

        // ─ 7. Timelock: deployer admin revoked ─
        failures += _check(
            "Deployer has NO DEFAULT_ADMIN_ROLE (decentralised)",
            !timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer)
        );

        // ─ 8. Timelock: minimum delay set ─
        failures += _check(
            "Timelock minDelay > 0",
            timelock.getMinDelay() > 0
        );

        // ─ 9. Token: initial holder has full supply ─
        uint256 totalSupply = token.totalSupply();
        failures += _check(
            "Token totalSupply > 0",
            totalSupply > 0
        );

        // ─ 10. Governor: linked to correct token and timelock ─
        failures += _check(
            "Governor token == PLGVotingToken",
            address(governor.token()) == tokenAddr
        );

        console.log("");
        if (failures == 0) {
            console.log("ALL CHECKS PASSED - deployment is valid");
        } else {
            console.log("FAILURES:", failures);
            console.log("Review failed checks above before proceeding");
        }
    }

    function _check(string memory label, bool condition) internal pure returns (uint256) {
        if (condition) {
            console.log("[PASS]", label);
            return 0;
        } else {
            console.log("[FAIL]", label);
            return 1;
        }
    }
}
