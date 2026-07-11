// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PLGGiftRouter} from "../src/PLGGiftRouter.sol";
import {PLGGovernor} from "../src/PLGGovernor.sol";
import {PLGTimelock} from "../src/PLGTimelock.sol";
import {PLGVotingToken} from "../src/PLGVotingToken.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @notice Integration tests for the PLG Governance system.
 *
 * Governance flow being tested:
 *   1. Token holders self-delegate to activate voting power
 *   2. Proposer submits a proposal targeting PLGGiftRouter
 *   3. After voting delay, voters cast votes
 *   4. After voting period, proposal is queued in timelock
 *   5. After timelock delay, anyone can execute
 *   6. PLGGiftRouter state has changed
 *
 * Tests also verify that direct calls to PLGGiftRouter are blocked
 * when validatorSet = timelock (bypassing governance).
 */
contract PLGGovernanceTest is Test {

    // ─ Contracts ─
    PLGVotingToken  public token;
    PLGTimelock     public timelock;
    PLGGovernor     public governor;
    PLGGiftRouter   public router;
    MockERC20       public usdc;

    // ─ Actors ─
    address public deployer;
    address public voter1;
    address public voter2;
    address public childAnchor;
    address public operationsWallet;

    // ─ Governance settings (in blocks for Governor, seconds for Timelock) ─
    uint48  public constant VOTING_DELAY   = 2;           // 2 blocks
    uint32  public constant VOTING_PERIOD  = 10;          // 10 blocks
    uint256 public constant QUORUM_PCT     = 4;           // 4%
    uint256 public constant PROPOSAL_THRESHOLD = 1e18;
    uint256 public constant TIMELOCK_DELAY = 2 days;      // Timelock uses seconds

    // ─ Token supply ─
    uint256 public constant INITIAL_SUPPLY = 1_000_000e18;

    bytes32 public genesisHash;

    function setUp() public {
        deployer         = makeAddr("deployer");
        voter1           = makeAddr("voter1");
        voter2           = makeAddr("voter2");
        childAnchor      = makeAddr("childAnchor");
        operationsWallet = makeAddr("operationsWallet");

        genesisHash = keccak256(abi.encodePacked("genesis_intent"));

        // ─ Deploy voting token ─
        vm.startPrank(deployer);
        token = new PLGVotingToken(deployer, INITIAL_SUPPLY);

        // ─ Distribute tokens to voters ─
        token.transfer(voter1, 400_000e18);  // 40% of supply
        token.transfer(voter2, 400_000e18);  // 40% of supply
        // deployer retains 20%
        vm.stopPrank();

        // ─ Self-delegate voting power ─
        vm.prank(voter1);
        token.delegate(voter1);
        vm.prank(voter2);
        token.delegate(voter2);
        vm.prank(deployer);
        token.delegate(deployer);

        // ─ Deploy timelock ─
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0);  // anyone can propose (governor will restrict)
        executors[0] = address(0);  // anyone can execute once ready
        timelock = new PLGTimelock(TIMELOCK_DELAY, proposers, executors, deployer);

        // ─ Deploy governor ─
        governor = new PLGGovernor(
            token,
            timelock,
            VOTING_DELAY,
            VOTING_PERIOD,
            PROPOSAL_THRESHOLD,
            QUORUM_PCT
        );

        // ─ Grant governor PROPOSER and CANCELLER roles ─
        vm.startPrank(deployer);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        // Revoke deployer admin so timelock is self-governing
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);
        vm.stopPrank();

        // ─ Deploy PLGGiftRouter with timelock as validatorSet ─
        usdc = new MockERC20("USDC", "USDC", 6);
        router = new PLGGiftRouter(
            2500,
            500,
            genesisHash,
            keccak256(abi.encodePacked("whitelist")),
            childAnchor,
            address(timelock),       // validatorSet = timelock (enforces governance)
            operationsWallet,
            block.chainid
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DEPLOYMENT & SETUP TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_router_validator_is_timelock() public view {
        assertEq(router.validatorSet(), address(timelock));
    }

    function test_token_balances_set_correctly() public view {
        assertEq(token.balanceOf(voter1), 400_000e18);
        assertEq(token.balanceOf(voter2), 400_000e18);
        assertEq(token.balanceOf(deployer), 200_000e18);
    }

    function test_voting_power_delegated() public view {
        assertEq(token.getVotes(voter1), 400_000e18);
        assertEq(token.getVotes(voter2), 400_000e18);
        assertEq(token.getVotes(deployer), 200_000e18);
    }

    function test_timelock_delay_is_correct() public view {
        assertEq(timelock.getMinDelay(), TIMELOCK_DELAY);
    }

    function test_direct_call_bypassing_governance_reverts() public {
        // Direct call to router without going through timelock must revert
        vm.prank(deployer);
        vm.expectRevert("Only validator set can call");
        router.setFeeOpsBps(800);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FULL GOVERNANCE FLOW: PROPOSE → VOTE → QUEUE → EXECUTE
    // ═══════════════════════════════════════════════════════════════════════════

    function test_governance_can_update_fee_ops_bps() public {
        uint16 newFee = 800; // 8%

        // ─ Step 1: Build proposal ─
        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);

        targets[0]   = address(router);
        values[0]    = 0;
        calldatas[0] = abi.encodeWithSignature("setFeeOpsBps(uint16)", newFee);

        string memory description = "Proposal: Raise ops fee to 8%";

        // ─ Step 2: Submit proposal ─
        vm.roll(block.number + 1);  // ensure delegation checkpointed
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));

        // ─ Step 3: Wait for voting delay ─
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        // ─ Step 4: Cast votes (1 = For) ─
        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        // ─ Step 5: Wait for voting period to end ─
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        // ─ Step 6: Queue in timelock ─
        governor.queue(targets, values, calldatas, keccak256(bytes(description)));
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        // ─ Step 7: Wait for timelock delay ─
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);

        // ─ Step 8: Execute ─
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));

        // ─ Verify state changed ─
        assertEq(router.feeOpsBps(), newFee);
    }

    function test_governance_can_update_child_share_bps() public {
        uint16 newShare = 3000; // raise to 30%

        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setMinChildShareBps(uint16)", newShare);

        string memory description = "Proposal: Raise child share to 30%";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        assertEq(router.minChildShareBps(), newShare);
    }

    function test_governance_cannot_lower_child_share_below_floor() public {
        uint16 belowFloor = 2000; // below MIN_CHILD_FLOOR (2500)

        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setMinChildShareBps(uint16)", belowFloor);

        string memory description = "Proposal: Attempt to lower child share below floor";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);

        // Execute must revert because router enforces MIN_CHILD_FLOOR
        vm.expectRevert();
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        // State unchanged
        assertEq(router.minChildShareBps(), 2500);
    }

    function test_proposal_defeated_if_quorum_not_reached() public {
        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setFeeOpsBps(uint16)", uint16(800));

        string memory description = "Proposal: Fee change with no quorum";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        // No votes cast — quorum not reached

        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_proposal_defeated_if_majority_votes_against() public {
        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setFeeOpsBps(uint16)", uint16(800));

        string memory description = "Proposal: Contested fee change";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);  // 40% For
        vm.prank(voter2);
        governor.castVote(proposalId, 0);  // 40% Against

        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_timelock_prevents_early_execution() public {
        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setFeeOpsBps(uint16)", uint16(800));

        string memory description = "Proposal: Fee change with timelock";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));

        // Attempt to execute before timelock delay — must revert
        vm.expectRevert();
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        // State still unchanged
        assertEq(router.feeOpsBps(), 500);
    }

    function test_governance_can_whitelist_attestor() public {
        address newAttestor = makeAddr("newAttestor");

        address[] memory targets  = new address[](1);
        uint256[] memory values   = new uint256[](1);
        bytes[]   memory calldatas = new bytes[](1);
        targets[0]   = address(router);
        calldatas[0] = abi.encodeWithSignature("setAttestor(address,bool)", newAttestor, true);

        string memory description = "Proposal: Whitelist new attestor";

        vm.roll(block.number + 1);
        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        assertTrue(router.isAttestor(newAttestor));
    }

    function test_governor_settings_correct() public view {
        assertEq(governor.votingDelay(),    VOTING_DELAY);
        assertEq(governor.votingPeriod(),   VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), PROPOSAL_THRESHOLD);
    }
}
