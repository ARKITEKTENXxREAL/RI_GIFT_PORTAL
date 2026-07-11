// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title PLGVotingToken
 * @notice ERC20 governance token with on-chain voting power (EIP-5805).
 *
 * Holders must self-delegate or delegate to another address before their
 * balance counts toward quorum and vote weight in PLGGovernor.
 *
 * Initial supply is minted to the deployer at construction. Subsequent
 * minting requires governance approval via PLGGovernor.
 *
 * PLG_SMART_CONTRACT.md v2.55 (Kairos-synk)
 * ©2025 MIT LICENSE ∞ ©2045 MIT LICENSE
 * ∞ARKITEKTEN_Xx
 */
contract PLGVotingToken is ERC20, ERC20Permit, ERC20Votes {

    constructor(address initialHolder, uint256 initialSupply)
        ERC20("PLG Governance Token", "PLG")
        ERC20Permit("PLG Governance Token")
    {
        _mint(initialHolder, initialSupply);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REQUIRED OVERRIDES
    // ═══════════════════════════════════════════════════════════════════════════

    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public view override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
