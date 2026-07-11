// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Deploy}         from "../script/Deploy.s.sol";
import {DeployConfig}   from "../script/DeployConfig.sol";
import {PLGGiftRouter}  from "../src/PLGGiftRouter.sol";
import {PLGTimelock}    from "../src/PLGTimelock.sol";
import {PLGGovernor}    from "../src/PLGGovernor.sol";
import {PLGVotingToken} from "../src/PLGVotingToken.sol";
import {IGovernor}      from "@openzeppelin/contracts/governance/IGovernor.sol";

/**
 * @notice End-to-end test that runs the Deploy script on a local fork
 *         and verifies all post-deploy invariants.
 *
 * Simulates a complete deployment without needing live RPC endpoints.
 * Uses Foundry's vm.setEnv to inject the required env vars.
 */
contract DeployTest is Test {

    Deploy public deployScript;

    address public childAnchor;
    address public operationsWallet;
    address public initialHolder;
    address public deployer;

    PLGVotingToken  public token;
    PLGTimelock     public timelock;
    PLGGovernor     public governor;
    PLGGiftRouter   public router;

    function setUp() public {
        childAnchor       = makeAddr("childAnchor");
        operationsWallet  = makeAddr("operationsWallet");
        initialHolder     = makeAddr("initialHolder");
        deployer          = makeAddr("deployer");

        deal(deployer, 10 ether);

        // ─ Set env vars expected by Deploy.s.sol ─
        vm.setEnv("PLG_CHILD_ANCHOR",   vm.toString(childAnchor));
        vm.setEnv("PLG_OPS_WALLET",     vm.toString(operationsWallet));
        vm.setEnv("PLG_TOKEN_HOLDER",   vm.toString(initialHolder));
        vm.setEnv("PLG_EVERGLOW_SEED",  vm.toString(bytes32(keccak256("genesis_intent"))));
        vm.setEnv("DEPLOYER_ADDRESS",   vm.toString(deployer));

        // ─ Run deploy script directly (no prank needed - script uses vm.startBroadcast internally) ─
        deployScript = new Deploy();
        deployScript.run();

        token    = deployScript.token();
        timelock = deployScript.timelock();
        governor = deployScript.governor();
        router   = deployScript.router();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DEPLOYMENT CORRECTNESS TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_all_contracts_deployed() public view {
        assertTrue(address(token)    != address(0));
        assertTrue(address(timelock) != address(0));
        assertTrue(address(governor) != address(0));
        assertTrue(address(router)   != address(0));
    }

    function test_router_validator_is_timelock() public view {
        assertEq(router.validatorSet(), address(timelock));
    }

    function test_router_chain_id_matches() public view {
        assertEq(router.chainId(), block.chainid);
    }

    function test_router_child_share_at_floor() public view {
        assertEq(router.minChildShareBps(), 2500);
    }

    function test_router_fee_ops_at_initial_value() public view {
        assertEq(router.feeOpsBps(), 500);
    }

    function test_timelock_min_delay_set() public view {
        assertEq(timelock.getMinDelay(), 60);  // localhost config: 60s
    }

    function test_governor_has_proposer_role() public view {
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
    }

    function test_governor_has_canceller_role() public view {
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), address(governor)));
    }

    function test_deployer_admin_revoked() public view {
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_token_supply_minted_to_initial_holder() public view {
        uint256 supply = 1_000_000e18;
        assertEq(token.balanceOf(initialHolder), supply);
        assertEq(token.totalSupply(), supply);
    }

    function test_governor_token_is_plg_token() public view {
        assertEq(address(governor.token()), address(token));
    }

    function test_governor_timelock_is_plg_timelock() public view {
        assertEq(address(governor.timelock()), address(timelock));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // POST-DEPLOY GOVERNANCE FLOW TEST
    // ═══════════════════════════════════════════════════════════════════════════

    function test_full_governance_flow_post_deploy() public {
        // Holder self-delegates to activate voting power
        vm.prank(initialHolder);
        token.delegate(initialHolder);

        // Advance one block to checkpoint
        vm.roll(block.number + 1);

        // Build a proposal to update fee
        address[] memory targets   = new address[](1);
        uint256[] memory values    = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setFeeOpsBps(uint16)", uint16(700));
        string memory description  = "Raise fee to 7%";

        // Propose
        vm.prank(initialHolder);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Pass voting delay (2 blocks for localhost)
        vm.roll(block.number + 3);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        // Vote
        vm.prank(initialHolder);
        governor.castVote(proposalId, 1);

        // Pass voting period (10 blocks for localhost)
        vm.roll(block.number + 11);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        // Queue
        governor.queue(targets, values, calldatas, keccak256(bytes(description)));

        // Pass timelock (60s for localhost)
        vm.warp(block.timestamp + 61);

        // Execute
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        // Verify
        assertEq(router.feeOpsBps(), 700);
    }
}
