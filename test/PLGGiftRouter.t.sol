// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PLGGiftRouter} from "../src/PLGGiftRouter.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract PLGGiftRouterTest is Test {
    PLGGiftRouter public router;
    MockERC20 public usdc;

    address public validator;
    address public childAnchor;
    address public operationsWallet;
    address public donor;
    address public attestor;
    address public node1;

    bytes32 public genesisHash;
    bytes32 public intentHash;
    bytes public emptyAttestation;

    event Genesis(
        uint16 indexed minChildShareBps,
        uint16 indexed feeOpsBps,
        bytes32 everglowSeedHash,
        bytes32 walletWhitelistHash,
        address indexed validatorSet,
        uint256 chainId
    );

    function setUp() public {
        validator = makeAddr("validator");
        childAnchor = makeAddr("childAnchor");
        operationsWallet = makeAddr("operationsWallet");
        donor = makeAddr("donor");
        node1 = makeAddr("node1");
        
        // Use a specific private key for attestor (1 in this case)
        attestor = vm.addr(1);

        genesisHash = keccak256(abi.encodePacked("genesis_intent"));
        intentHash = keccak256(abi.encodePacked("donation_intent"));
        emptyAttestation = "";

        // Deploy mock USDC
        usdc = new MockERC20("USDC", "USDC", 6);

        // Deploy router with genesis parameters
        router = new PLGGiftRouter(
            2500,                  // minChildShareBps = 25%
            500,                   // feeOpsBps = 5%
            genesisHash,           // everglowSeedHash
            keccak256(abi.encodePacked(node1)),  // walletWhitelistHash
            childAnchor,           // childAnchor
            validator,             // validatorSet
            operationsWallet,      // operationsWallet
            block.chainid          // chainId
        );

        // Setup: fund donor with ETH and ERC20
        deal(donor, 100 ether);
        usdc.mint(donor, 1000e6);

        // Setup: approve router to spend donor's USDC
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Setup: register attestor
        vm.prank(validator);
        router.setAttestor(attestor, true);

        // Setup: whitelist node1
        vm.prank(validator);
        router.setNode(node1, true);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_constructor_emits_genesis_event() public {
        vm.expectEmit(true, true, true, true);
        emit Genesis(2500, 500, genesisHash, keccak256(abi.encodePacked(node1)), validator, block.chainid);

        new PLGGiftRouter(
            2500,
            500,
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            validator,
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_invalid_child_anchor() public {
        vm.expectRevert("Invalid child anchor");
        new PLGGiftRouter(
            2500,
            500,
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            address(0),  // Invalid
            validator,
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_invalid_validator() public {
        vm.expectRevert("Invalid validator");
        new PLGGiftRouter(
            2500,
            500,
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            address(0),  // Invalid
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_child_share_below_floor() public {
        vm.expectRevert("Child share below floor (min 2500 bps)");
        new PLGGiftRouter(
            2000,  // Below MIN_CHILD_FLOOR (2500)
            500,
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            validator,
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_fee_exceeding_cap() public {
        vm.expectRevert("Fee exceeds cap (max 1000 bps)");
        new PLGGiftRouter(
            2500,
            2000,  // Exceeds MAX_FEE_CAP (1000)
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            validator,
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_total_bps_exceeding_100() public {
        vm.expectRevert("Total BPS exceeds 100%");
        new PLGGiftRouter(
            9500,  // 95%
            1000,  // 10% (at fee cap) → Total 105% > 100%
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            validator,
            operationsWallet,
            block.chainid
        );
    }

    function test_constructor_rejects_wrong_chain() public {
        vm.expectRevert("Wrong chain");
        new PLGGiftRouter(
            2500,
            500,
            genesisHash,
            keccak256(abi.encodePacked(node1)),
            childAnchor,
            validator,
            operationsWallet,
            999  // Wrong chain ID
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DONATE ERC20 TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_donateERC20_distributes_correctly() public {
        uint256 donationAmount = 100e6;  // 100 USDC
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Create valid EIP-712 signature
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Expected distribution:
        // 25% (25e6) → childAnchor
        // 5% (5e6) → operationsWallet
        // 70% (70e6) → childAnchor (remainder in MVP)

        assertEq(usdc.balanceOf(childAnchor), 95e6);  // 25 + 70
        assertEq(usdc.balanceOf(operationsWallet), 5e6);
        assertEq(usdc.balanceOf(donor), 900e6);  // 1000 - 100
    }

    function test_donateERC20_calculates_shares() public {
        (uint256 childShare, uint256 feeShare, uint256 remainingShare) = 
            router.calculateDistribution(100e6);

        assertEq(childShare, 25e6);   // 25%
        assertEq(feeShare, 5e6);      // 5%
        assertEq(remainingShare, 70e6); // 70%
    }

    function test_donateERC20_rejects_zero_amount() public {
        vm.prank(donor);
        vm.expectRevert("Amount must be greater than zero");
        router.donateERC20(address(usdc), 0, intentHash, abi.encode(attestor));
    }

    function test_donateERC20_holds_funds_if_seed_filter_fails() public {
        uint256 donationAmount = 100e6;

        // Try with empty attestation (will fail SEED filter)
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        // Funds should be held, not distributed
        assertEq(usdc.balanceOf(childAnchor), 0);
        assertEq(usdc.balanceOf(operationsWallet), 0);
        assertEq(usdc.balanceOf(address(router)), donationAmount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DONATE ETH TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_donateETH_distributes_correctly() public {
        uint256 donationAmount = 1 ether;
        bytes32 txId = _computeTxId(donor, donationAmount, address(0), 0);
        
        uint256 childBalanceBefore = childAnchor.balance;
        uint256 opsBalanceBefore = operationsWallet.balance;

        // Create valid EIP-712 signature
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(0), intentHash);

        vm.prank(donor);
        router.donateETH{value: donationAmount}(intentHash, attestation);

        // Expected distribution:
        // 25% (0.25 ether) → childAnchor
        // 5% (0.05 ether) → operationsWallet
        // 70% (0.70 ether) → childAnchor

        assertEq(childAnchor.balance, childBalanceBefore + 0.95 ether);
        assertEq(operationsWallet.balance, opsBalanceBefore + 0.05 ether);
    }

    function test_donateETH_via_receive() public {
        uint256 donationAmount = 1 ether;

        vm.prank(donor);
        (bool success,) = payable(address(router)).call{value: donationAmount}("");
        require(success);

        // Should be held (with default empty intent), so funds should remain in contract
        // OR if we want receive to accept donations, funds should distribute
        // For now: funds are held by default
        assertEq(address(router).balance, donationAmount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHILD-FIRST TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_child_share_is_immutable_floor() public {
        // Attempt to lower minChildShareBps below floor
        vm.prank(validator);
        vm.expectRevert("Cannot lower below hard floor");
        router.setMinChildShareBps(2000);  // Below MIN_CHILD_FLOOR
    }

    function test_child_share_can_increase() public {
        vm.prank(validator);
        router.setMinChildShareBps(3000);  // Increase from 2500 to 3000

        assertEq(router.minChildShareBps(), 3000);
    }

    function test_dust_donation_rejected() public {
        // Create a donation so small that child share rounds to 0
        // Minimum: (1 wei * 2500) / 10000 = 0.25 wei → rounds down to 0

        vm.prank(donor);
        usdc.mint(donor, 1);  // 1 wei worth
        vm.prank(donor);
        usdc.approve(address(router), 1);

        vm.prank(donor);
        vm.expectRevert("Child share too small");
        router.donateERC20(address(usdc), 1, intentHash, abi.encode(attestor));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GOVERNANCE TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_only_validator_can_set_child_anchor() public {
        address newAnchor = makeAddr("newAnchor");

        vm.prank(donor);  // Non-validator
        vm.expectRevert("Only validator set can call");
        router.setChildAnchor(newAnchor);
    }

    function test_validator_can_set_child_anchor() public {
        address newAnchor = makeAddr("newAnchor");

        vm.prank(validator);
        router.setChildAnchor(newAnchor);

        assertEq(router.childAnchor(), newAnchor);
    }

    function test_validator_can_set_fee_ops_bps() public {
        vm.prank(validator);
        router.setFeeOpsBps(800);  // 8%

        assertEq(router.feeOpsBps(), 800);
    }

    function test_fee_ops_bps_cannot_exceed_cap() public {
        vm.prank(validator);
        vm.expectRevert("Exceeds fee cap");
        router.setFeeOpsBps(2000);  // 20% > MAX_FEE_CAP (10%)
    }

    function test_validator_can_whitelist_node() public {
        address newNode = makeAddr("newNode");

        vm.prank(validator);
        router.setNode(newNode, true);

        assertTrue(router.isNode(newNode));
    }

    function test_validator_can_register_attestor() public {
        address newAttestor = makeAddr("newAttestor");

        vm.prank(validator);
        router.setAttestor(newAttestor, true);

        assertTrue(router.isAttestor(newAttestor));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FEILBANE (ERROR PATH) TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_held_funds_can_be_refunded() public {
        uint256 donationAmount = 100e6;

        // Make donation with bad intent (will be held)
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        // Get the transaction ID (in real code, would be emitted)
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Validator initiates review
        vm.prank(validator);
        router.initiateReview(txId);

        // Validator resolves with REFUND
        vm.prank(validator);
        router.resolveHold(txId, "REFUND", address(0));

        // Donor should receive funds back
        assertEq(usdc.balanceOf(donor), 1000e6);  // Back to original
    }

    function test_held_funds_can_be_donated_to_child() public {
        uint256 donationAmount = 100e6;

        // Make donation with bad intent (will be held)
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Validator resolves with DONATE_TO_CHILD
        vm.prank(validator);
        router.resolveHold(txId, "DONATE_TO_CHILD", address(0));

        // Full amount should go to child anchor
        assertEq(usdc.balanceOf(childAnchor), donationAmount);
    }

    function test_held_funds_can_be_rerouted() public {
        uint256 donationAmount = 100e6;
        address reroute_target = makeAddr("reroute_target");

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        vm.prank(validator);
        router.resolveHold(txId, "REROUTE", reroute_target);

        assertEq(usdc.balanceOf(reroute_target), donationAmount);
    }

    function test_held_funds_can_be_locked() public {
        uint256 donationAmount = 100e6;

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        vm.prank(validator);
        router.resolveHold(txId, "LOCK", address(0));

        // Funds remain in contract and resolved is still false (LOCK does not finalize)
        assertEq(usdc.balanceOf(address(router)), donationAmount);
        PLGGiftRouter.HeldFunds memory hf = router.getHeldFunds(txId);
        assertFalse(hf.resolved, "LOCK must not mark resolved=true");

        // Governance can still resolve after a LOCK
        vm.prank(validator);
        router.resolveHold(txId, "REFUND", address(0));
        assertEq(usdc.balanceOf(donor), 1000e6);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EDGE CASES
    // ═══════════════════════════════════════════════════════════════════════════

    function test_multiple_donations_accumulate_correctly() public {
        uint256 amount1 = 100e6;
        uint256 amount2 = 50e6;
        
        // First donation - compute txId exactly as contract does
        bytes32 txId1 = _computeTxId(donor, amount1, address(usdc), 0);
        bytes memory attestation1 = _createAttestation(txId1, donor, amount1, address(usdc), intentHash);

        vm.prank(donor);
        router.donateERC20(address(usdc), amount1, intentHash, attestation1);

        // Give donor more USDC for second donation
        usdc.mint(donor, 100e6);

        // Second donation - move forward one block
        vm.roll(block.number + 1);
        
        bytes32 txId2 = _computeTxId(donor, amount2, address(usdc), 1);
        bytes memory attestation2 = _createAttestation(txId2, donor, amount2, address(usdc), intentHash);

        vm.prank(donor);
        router.donateERC20(address(usdc), amount2, intentHash, attestation2);

        // Total distributed: 95 from first + 47.5 from second = 142.5e6 to childAnchor, 5 + 2.5 = 7.5e6 to ops
        assertEq(usdc.balanceOf(childAnchor), 142.5e6);
        assertEq(usdc.balanceOf(operationsWallet), 7.5e6);
    }

    function test_cannot_double_resolve_held_funds() public {
        uint256 donationAmount = 100e6;

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, bytes32(0), "");

        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        vm.prank(validator);
        router.resolveHold(txId, "REFUND", address(0));

        // Try to resolve again
        vm.prank(validator);
        vm.expectRevert("Already resolved");
        router.resolveHold(txId, "REFUND", address(0));
    }

    function test_genesis_state_immutable() public {
        // Verify genesis parameters are set correctly
        assertEq(router.minChildShareBps(), 2500);
        assertEq(router.feeOpsBps(), 500);
        assertEq(router.chainId(), block.chainid);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NODE DISTRIBUTION TESTS (Phase 2B)
    // ═══════════════════════════════════════════════════════════════════════════

    function test_set_node_weight_requires_whitelist() public {
        address newNode = makeAddr("newNode");
        vm.prank(validator);
        vm.expectRevert("Node not whitelisted");
        router.setNodeWeight(newNode, 100);
    }

    function test_set_node_weight_updates_total_weight() public {
        address node2 = makeAddr("node2");
        vm.prank(validator);
        router.setNode(node2, true);

        vm.prank(validator);
        router.setNodeWeight(node1, 100);
        vm.prank(validator);
        router.setNodeWeight(node2, 200);

        assertEq(router.totalNodeWeight(), 300);
        assertEq(router.getNodeWeight(node1), 100);
        assertEq(router.getNodeWeight(node2), 200);
    }

    function test_set_node_weight_adds_to_active_nodes() public {
        assertEq(router.getActiveNodeCount(), 0);

        vm.prank(validator);
        router.setNodeWeight(node1, 100);

        assertEq(router.getActiveNodeCount(), 1);
        assertEq(router.getActiveNodeAt(0), node1);
    }

    function test_set_node_weight_to_zero_removes_active_node() public {
        address node2 = makeAddr("node2");
        vm.prank(validator);
        router.setNode(node2, true);

        vm.prank(validator);
        router.setNodeWeight(node1, 100);
        vm.prank(validator);
        router.setNodeWeight(node2, 200);

        assertEq(router.getActiveNodeCount(), 2);

        // Remove node1 by setting weight to 0
        vm.prank(validator);
        router.setNodeWeight(node1, 0);

        assertEq(router.getActiveNodeCount(), 1);
        assertEq(router.totalNodeWeight(), 200);
    }

    function test_remove_node_resets_weight() public {
        vm.prank(validator);
        router.setNodeWeight(node1, 100);
        assertEq(router.totalNodeWeight(), 100);
        assertEq(router.getActiveNodeCount(), 1);

        // Removing node from whitelist should reset weight and remove from activeNodes (Alert 6 fix)
        vm.prank(validator);
        router.setNode(node1, false);

        assertEq(router.totalNodeWeight(), 0);
        assertEq(router.getNodeWeight(node1), 0);
        assertEq(router.getActiveNodeCount(), 0, "setNode(false) must remove from activeNodes");
    }

    function test_removed_node_can_be_readded_without_duplicate() public {
        vm.prank(validator);
        router.setNodeWeight(node1, 100);

        // Remove node
        vm.prank(validator);
        router.setNode(node1, false);
        assertEq(router.getActiveNodeCount(), 0);

        // Re-add and re-weight
        vm.prank(validator);
        router.setNode(node1, true);
        vm.prank(validator);
        router.setNodeWeight(node1, 200);

        // Should appear exactly once in activeNodes
        assertEq(router.getActiveNodeCount(), 1);
        assertEq(router.getActiveNodeAt(0), node1);
        assertEq(router.totalNodeWeight(), 200);
    }

    function test_node_eth_rewards_use_pull_payment() public {
        vm.prank(validator);
        router.setNodeWeight(node1, 100);

        uint256 donation = 1 ether;
        vm.deal(donor, donation);
        bytes32 txId = _computeTxId(donor, donation, address(0), 0);
        bytes memory attestation = _createAttestation(txId, donor, donation, address(0), intentHash);

        vm.prank(donor);
        router.donateETH{value: donation}(intentHash, attestation);

        // Node should have pending withdrawal, not direct ETH balance change
        uint256 expectedRemainder = donation * (10000 - 2500 - 500) / 10000;
        assertEq(router.pendingWithdrawals(node1), expectedRemainder);

        // Node withdraws ETH
        uint256 balBefore = node1.balance;
        vm.prank(node1);
        router.withdrawNodeRewards();
        assertEq(node1.balance - balBefore, expectedRemainder);
        assertEq(router.pendingWithdrawals(node1), 0);
    }


    function test_no_active_nodes_sends_remainder_to_child() public {
        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        // No nodes have weights set
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Remainder (70%) should fall back to childAnchor
        assertEq(usdc.balanceOf(childAnchor), donationAmount * 9500 / 10000);
        assertEq(usdc.balanceOf(operationsWallet), donationAmount * 500 / 10000);
    }

    function test_single_node_receives_full_remainder() public {
        // Set node1 weight
        vm.prank(validator);
        router.setNodeWeight(node1, 100);

        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // node1 should receive 70% remainder
        assertEq(usdc.balanceOf(node1), 70e6);
        // childAnchor should only receive its 25%
        assertEq(usdc.balanceOf(childAnchor), 25e6);
        assertEq(usdc.balanceOf(operationsWallet), 5e6);
    }

    function test_two_nodes_split_remainder_proportionally() public {
        address node2 = makeAddr("node2");
        vm.prank(validator);
        router.setNode(node2, true);

        // node1 = 1/3 weight, node2 = 2/3 weight
        vm.prank(validator);
        router.setNodeWeight(node1, 100);
        vm.prank(validator);
        router.setNodeWeight(node2, 200);

        uint256 donationAmount = 300e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Remainder = 70% of 300e6 = 210e6
        // node1 share = 1/3 of 210e6 = 70e6
        // node2 share = 2/3 of 210e6 = 140e6
        assertEq(usdc.balanceOf(node1), 70e6);
        assertEq(usdc.balanceOf(node2), 140e6);
    }

    function test_node_rewards_accumulate_over_donations() public {
        vm.prank(validator);
        router.setNodeWeight(node1, 100);

        uint256 donationAmount = 100e6;
        bytes32 txId1 = _computeTxId(donor, donationAmount, address(usdc), 0);
        bytes memory attestation1 = _createAttestation(txId1, donor, donationAmount, address(usdc), intentHash);
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation1);

        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        vm.roll(block.number + 1);
        bytes32 txId2 = _computeTxId(donor, donationAmount, address(usdc), 1);
        bytes memory attestation2 = _createAttestation(txId2, donor, donationAmount, address(usdc), intentHash);
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation2);

        // node1 should have accumulated 70e6 + 70e6 = 140e6 in rewards
        assertEq(router.getNodeRewards(node1), 140e6);
    }

    function test_calculate_node_share_view() public {
        address node2 = makeAddr("node2");
        vm.prank(validator);
        router.setNode(node2, true);

        vm.prank(validator);
        router.setNodeWeight(node1, 300);
        vm.prank(validator);
        router.setNodeWeight(node2, 700);

        uint256 remainder = 100e6;
        assertEq(router.calculateNodeShare(node1, remainder), 30e6);   // 30%
        assertEq(router.calculateNodeShare(node2, remainder), 70e6);   // 70%
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EIP-712 ATTESTATION TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_valid_eip712_attestation_passes() public {
        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Mint tokens to donor
        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Create valid EIP-712 signature from attestor
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        // Donate with valid attestation
        uint256 childBalanceBefore = childAnchor.balance;
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Funds should be distributed (not held)
        assertEq(usdc.balanceOf(address(router)), 0);
        assertEq(usdc.balanceOf(childAnchor), donationAmount * 2500 / 10000 + donationAmount * 7000 / 10000);
    }

    function test_invalid_signature_holds_funds() public {
        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Mint tokens to donor
        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Create invalid signature (from non-approved address)
        address notAttestor = makeAddr("notAttestor");
        bytes memory invalidAttestation = _createAttestationFrom(txId, donor, donationAmount, address(usdc), intentHash, notAttestor);

        // Donate with invalid attestation
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, invalidAttestation);

        // Funds should be held (not distributed)
        assertEq(usdc.balanceOf(address(router)), donationAmount);
        assertEq(usdc.balanceOf(childAnchor), 0);
    }

    function test_replay_attack_prevented() public {
        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Mint tokens to donor
        usdc.mint(donor, donationAmount * 2);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Create valid signature
        bytes memory attestation = _createAttestation(txId, donor, donationAmount, address(usdc), intentHash);

        // First donation with this signature should succeed
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Second donation with same signature should be held (replay detected)
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Second donation should be held
        assertEq(usdc.balanceOf(address(router)), donationAmount);
    }

    function test_empty_attestation_holds_funds() public {
        uint256 donationAmount = 100e6;

        // Mint tokens to donor
        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Donate with empty attestation
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, "");

        // Funds should be held
        assertEq(usdc.balanceOf(address(router)), donationAmount);
    }

    function test_unapproved_attestor_signature_fails() public {
        uint256 donationAmount = 100e6;
        bytes32 txId = _computeTxId(donor, donationAmount, address(usdc), 0);

        // Mint tokens to donor
        usdc.mint(donor, donationAmount);
        vm.prank(donor);
        usdc.approve(address(router), type(uint256).max);

        // Create attestation from unapproved address
        address unapprovedAttestor = makeAddr("unapprovedAttestor");
        bytes memory attestation = _createAttestationFrom(txId, donor, donationAmount, address(usdc), intentHash, unapprovedAttestor);

        // Donate with unapproved attestor signature
        vm.prank(donor);
        router.donateERC20(address(usdc), donationAmount, intentHash, attestation);

        // Funds should be held
        assertEq(usdc.balanceOf(address(router)), donationAmount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EIP-712 HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function _createAttestation(
        bytes32 txId,
        address donor,
        uint256 amount,
        address token,
        bytes32 intentHash
    ) internal view returns (bytes memory) {
        return _createAttestationFrom(txId, donor, amount, token, intentHash, attestor);
    }

    function _createAttestationFrom(
        bytes32 txId,
        address donor,
        uint256 amount,
        address token,
        bytes32 intentHash,
        address signer
    ) internal view returns (bytes memory) {
        // Get domain separator (same as contract uses)
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PLGGiftRouter")),
            keccak256(bytes("1")),
            block.chainid,
            address(router)
        ));

        // Create struct hash matching ResonanceAttestation
        bytes32 structHash = keccak256(abi.encode(
            keccak256("ResonanceAttestation(bytes32 txId,address donor,uint256 amount,address token,bytes32 intentHash,uint256 timestamp,uint8 level)"),
            txId,
            donor,
            amount,
            token,
            intentHash,
            block.timestamp,
            uint8(1)
        ));

        // Create digest
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        // Determine private key for signer
        uint256 signerKey;
        if (signer == attestor) {
            signerKey = 1;  // Attestor uses private key 1
        } else {
            // For other signers, derive from address (deterministic but won't match real keys)
            signerKey = uint256(keccak256(abi.encodePacked(signer))) % type(uint256).max;
            if (signerKey == 0) signerKey = 1;
        }

        // Sign with signer key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);

        // Wrap in abi.encode(timestamp, level, sig) matching new contract format
        bytes memory sig = abi.encodePacked(r, s, v);
        return abi.encode(block.timestamp, uint8(1), sig);
    }

    // Matches contract txId derivation exactly:
    // keccak256(abi.encodePacked(msg.sender, _amount, _token, block.timestamp, block.number, nonce))
    function _computeTxId(address sender, uint256 amount, address token, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, amount, token, block.timestamp, block.number, nonce));
    }
}
