// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PLGGiftRouter}  from "../src/PLGGiftRouter.sol";
import {PLGTimelock}    from "../src/PLGTimelock.sol";
import {PLGGovernor}    from "../src/PLGGovernor.sol";
import {PLGVotingToken} from "../src/PLGVotingToken.sol";
import {DeployConfig}   from "./DeployConfig.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title Deploy
 * @notice Deploys the complete PLG system to any supported chain.
 *
 * Usage:
 *   # Dry-run (no broadcast):
 *   forge script script/Deploy.s.sol --rpc-url <chain> -vvvv
 *
 *   # Live deploy:
 *   forge script script/Deploy.s.sol \
 *     --rpc-url <chain> \
 *     --broadcast \
 *     --verify \
 *     --private-key $DEPLOYER_PRIVATE_KEY \
 *     -vvvv
 *
 * Required env vars:
 *   PLG_CHILD_ANCHOR        - BARNEFONDET wallet address
 *   PLG_OPS_WALLET          - Operations fee wallet address
 *   PLG_TOKEN_HOLDER        - Initial governance token holder (multisig)
 *   PLG_EVERGLOW_SEED       - Everglow SEED hash (bytes32 hex)
 *
 * Deployment order (all in one tx batch):
 *   1. PLGVotingToken   - governance token
 *   2. PLGTimelock      - timelock controller (validator = timelock)
 *   3. PLGGovernor      - on-chain governor
 *   4. PLGGiftRouter    - core routing contract
 *   5. Role setup       - grant Governor PROPOSER/CANCELLER on Timelock
 *   6. Admin revocation - revoke deployer admin from Timelock
 *
 * PLG_SMART_CONTRACT.md v2.55 (Kairos-synk)
 * ©2025 MIT LICENSE ∞ ©2045 MIT LICENSE
 * ∞ARKITEKTEN_Xx
 */
contract Deploy is Script {

    // Deployed addresses - populated during run()
    PLGVotingToken  public token;
    PLGTimelock     public timelock;
    PLGGovernor     public governor;
    PLGGiftRouter   public router;

    function run() external {
        // ─ Read required env vars ─
        address childAnchor       = vm.envAddress("PLG_CHILD_ANCHOR");
        address operationsWallet  = vm.envAddress("PLG_OPS_WALLET");
        address initialHolder     = vm.envAddress("PLG_TOKEN_HOLDER");
        bytes32 everglowSeedHash  = vm.envBytes32("PLG_EVERGLOW_SEED");
        address deployer          = vm.envAddress("DEPLOYER_ADDRESS");

        // ─ Select config based on current chain ─
        DeployConfig.Config memory cfg = _selectConfig(
            childAnchor,
            operationsWallet,
            initialHolder,
            everglowSeedHash
        );

        console.log("Deploying PLG system to:", cfg.chainName);
        console.log("Chain ID:", cfg.chainId);
        console.log("Child anchor:", cfg.childAnchor);
        console.log("Ops wallet:", cfg.operationsWallet);
        console.log("Initial token holder:", cfg.initialTokenHolder);

        vm.startBroadcast(deployer);

        // ─ 1. Deploy voting token ─
        token = new PLGVotingToken(cfg.initialTokenHolder, cfg.initialTokenSupply);
        console.log("PLGVotingToken deployed:", address(token));

        // ─ 2. Deploy timelock ─
        address[] memory proposers = new address[](0);  // Governor added after
        address[] memory executors = new address[](1);
        executors[0] = address(0);  // Anyone can execute once delay passes
        timelock = new PLGTimelock(cfg.timelockDelay, proposers, executors, deployer);
        console.log("PLGTimelock deployed:", address(timelock));

        // ─ 3. Deploy governor ─
        governor = new PLGGovernor(
            token,
            timelock,
            cfg.votingDelay,
            cfg.votingPeriod,
            cfg.proposalThreshold,
            cfg.quorumNumerator
        );
        console.log("PLGGovernor deployed:", address(governor));

        // ─ 4. Deploy router (validatorSet = timelock) ─
        router = new PLGGiftRouter(
            cfg.minChildShareBps,
            cfg.feeOpsBps,
            cfg.everglowSeedHash,
            cfg.walletWhitelistHash,
            cfg.childAnchor,
            address(timelock),      // governance controls all router params
            cfg.operationsWallet,
            cfg.chainId
        );
        console.log("PLGGiftRouter deployed:", address(router));

        // ─ 5. Grant governor PROPOSER + CANCELLER roles on timelock ─
        timelock.grantRole(timelock.PROPOSER_ROLE(),  address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        console.log("Governor roles granted on timelock");

        // ─ 6. Revoke deployer admin - timelock is now self-governing ─
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);
        console.log("Deployer admin revoked - system is fully decentralised");

        vm.stopBroadcast();

        // ─ Print summary ─
        _printSummary(cfg);
    }

    function _selectConfig(
        address childAnchor,
        address operationsWallet,
        address initialHolder,
        bytes32 everglowSeedHash
    ) internal view returns (DeployConfig.Config memory) {
        uint256 id = block.chainid;

        if (id == 1)     return DeployConfig.ethereum(childAnchor, operationsWallet, initialHolder, everglowSeedHash);
        if (id == 10)    return DeployConfig.optimism(childAnchor, operationsWallet, initialHolder, everglowSeedHash);
        if (id == 42161) return DeployConfig.arbitrum(childAnchor, operationsWallet, initialHolder, everglowSeedHash);
        if (id == 31337) return DeployConfig.localhost(childAnchor, operationsWallet, initialHolder, everglowSeedHash);

        revert("Unsupported chain - add config in DeployConfig.sol");
    }

    function _printSummary(DeployConfig.Config memory cfg) internal view {
        console.log("");
        console.log("=== PLG DEPLOYMENT COMPLETE ===");
        console.log("Chain:           ", cfg.chainName);
        console.log("Chain ID:        ", cfg.chainId);
        console.log("PLGVotingToken:  ", address(token));
        console.log("PLGTimelock:     ", address(timelock));
        console.log("PLGGovernor:     ", address(governor));
        console.log("PLGGiftRouter:   ", address(router));
        console.log("");
        console.log("Parameters:");
        console.log("  minChildShareBps:", cfg.minChildShareBps);
        console.log("  feeOpsBps:       ", cfg.feeOpsBps);
        console.log("  timelockDelay:   ", cfg.timelockDelay, "seconds");
        console.log("  votingDelay:     ", cfg.votingDelay, "blocks");
        console.log("  votingPeriod:    ", cfg.votingPeriod, "blocks");
        console.log("  quorum:          ", cfg.quorumNumerator, "%");
        console.log("");
        console.log("Save these addresses in deployments/<chain>.json");
    }
}
