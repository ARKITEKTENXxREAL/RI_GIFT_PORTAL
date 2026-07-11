// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DeployConfig
 * @notice Per-chain deployment parameters for PLG system.
 *
 * These values are read by Deploy.s.sol at deploy time.
 * All addresses and settings are chain-specific.
 *
 * PLG_SMART_CONTRACT.md v2.55 (Kairos-synk)
 * ©2025 MIT LICENSE ∞ ©2045 MIT LICENSE
 * ∞ARKITEKTEN_Xx
 */
library DeployConfig {

    struct Config {
        // ─ Chain identity ─
        uint256 chainId;
        string  chainName;

        // ─ PLGGiftRouter parameters ─
        uint16  minChildShareBps;    // 25% (2500) hard floor - never lower
        uint16  feeOpsBps;           // Initial ops fee (e.g., 500 = 5%)
        bytes32 everglowSeedHash;    // Everglow SEED filter root hash
        bytes32 walletWhitelistHash; // Initial node whitelist hash

        // ─ Recipient addresses ─
        address childAnchor;         // BARNEFONDET primary wallet
        address operationsWallet;    // Ops fee recipient

        // ─ Governance parameters ─
        uint256 timelockDelay;       // Minimum timelock delay (seconds)
        uint48  votingDelay;         // Blocks between proposal and voting start
        uint32  votingPeriod;        // Blocks for active voting window
        uint256 proposalThreshold;   // Min tokens to create proposal
        uint256 quorumNumerator;     // Quorum % (e.g., 4 = 4%)

        // ─ Voting token parameters ─
        uint256 initialTokenSupply;  // PLG governance token supply
        address initialTokenHolder;  // Receives full initial supply (typically multisig)
    }

    // ─────────────────────────────────────────────────────────────────
    // ETHEREUM MAINNET (chainId: 1)
    // ─────────────────────────────────────────────────────────────────
    function ethereum(
        address childAnchor,
        address operationsWallet,
        address initialTokenHolder,
        bytes32 everglowSeedHash
    ) internal pure returns (Config memory) {
        return Config({
            chainId:              1,
            chainName:            "ethereum",
            minChildShareBps:     2500,     // 25% hard floor
            feeOpsBps:            500,      // 5% ops fee
            everglowSeedHash:     everglowSeedHash,
            walletWhitelistHash:  keccak256(abi.encodePacked("PLG_NODE_WHITELIST_V1")),
            childAnchor:          childAnchor,
            operationsWallet:     operationsWallet,
            timelockDelay:        2 days,
            votingDelay:          7200,     // ~1 day at 12s/block
            votingPeriod:         21600,    // ~3 days at 12s/block
            proposalThreshold:    10_000e18,// 10k tokens to propose
            quorumNumerator:      4,        // 4% quorum
            initialTokenSupply:   1_000_000e18,
            initialTokenHolder:   initialTokenHolder
        });
    }

    // ─────────────────────────────────────────────────────────────────
    // OPTIMISM (chainId: 10)
    // ─────────────────────────────────────────────────────────────────
    function optimism(
        address childAnchor,
        address operationsWallet,
        address initialTokenHolder,
        bytes32 everglowSeedHash
    ) internal pure returns (Config memory) {
        return Config({
            chainId:              10,
            chainName:            "optimism",
            minChildShareBps:     2500,
            feeOpsBps:            500,
            everglowSeedHash:     everglowSeedHash,
            walletWhitelistHash:  keccak256(abi.encodePacked("PLG_NODE_WHITELIST_V1")),
            childAnchor:          childAnchor,
            operationsWallet:     operationsWallet,
            timelockDelay:        2 days,
            votingDelay:          3600,     // ~1 day at 2s/block on Optimism
            votingPeriod:         10800,    // ~3 days
            proposalThreshold:    10_000e18,
            quorumNumerator:      4,
            initialTokenSupply:   1_000_000e18,
            initialTokenHolder:   initialTokenHolder
        });
    }

    // ─────────────────────────────────────────────────────────────────
    // ARBITRUM ONE (chainId: 42161)
    // ─────────────────────────────────────────────────────────────────
    function arbitrum(
        address childAnchor,
        address operationsWallet,
        address initialTokenHolder,
        bytes32 everglowSeedHash
    ) internal pure returns (Config memory) {
        return Config({
            chainId:              42161,
            chainName:            "arbitrum",
            minChildShareBps:     2500,
            feeOpsBps:            500,
            everglowSeedHash:     everglowSeedHash,
            walletWhitelistHash:  keccak256(abi.encodePacked("PLG_NODE_WHITELIST_V1")),
            childAnchor:          childAnchor,
            operationsWallet:     operationsWallet,
            timelockDelay:        2 days,
            votingDelay:          14400,    // ~1 day at ~0.25s/block on Arbitrum
            votingPeriod:         43200,    // ~3 days
            proposalThreshold:    10_000e18,
            quorumNumerator:      4,
            initialTokenSupply:   1_000_000e18,
            initialTokenHolder:   initialTokenHolder
        });
    }

    // ─────────────────────────────────────────────────────────────────
    // LOCALHOST / ANVIL (chainId: 31337) - for testing deploy scripts
    // ─────────────────────────────────────────────────────────────────
    function localhost(
        address childAnchor,
        address operationsWallet,
        address initialTokenHolder,
        bytes32 everglowSeedHash
    ) internal pure returns (Config memory) {
        return Config({
            chainId:              31337,
            chainName:            "localhost",
            minChildShareBps:     2500,
            feeOpsBps:            500,
            everglowSeedHash:     everglowSeedHash,
            walletWhitelistHash:  keccak256(abi.encodePacked("PLG_NODE_WHITELIST_V1")),
            childAnchor:          childAnchor,
            operationsWallet:     operationsWallet,
            timelockDelay:        60,       // 1 minute for local testing
            votingDelay:          2,
            votingPeriod:         10,
            proposalThreshold:    1e18,
            quorumNumerator:      4,
            initialTokenSupply:   1_000_000e18,
            initialTokenHolder:   initialTokenHolder
        });
    }
}
