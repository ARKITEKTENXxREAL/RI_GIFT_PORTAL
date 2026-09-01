# Security Policy  
  
- **Governance / Github Organization** : `ARKITEKTENXxREAL`, `plgprotocol.io` & `The-Galactic-Federation-Of-Light`    

- **Repo** : `PLG_SMART_CONTRACT` & `RI_GIFT_PORTAL`  

- *Type of smart contract* : **A multi-chain charitable distribution protocol.**   

- **Main Inspo** : ARKITEKTENXxREAL / RI_GIFT_PORTAL / `PLG_SMART_CONTRACT.md` *v.2.55*  

## Security review status:  

 >The protocol `PLG_SMART_CONTRACT` has undergone structured,  
 AI-assisted security review (Claude and GitHub Copilot CLI) covering all four in-scope contracts.  
 Six findings were identified and resolved prior to testnet deployment;  
 each resolution is traceable in `src/` commit history under the `Phase 2E` tag.  
 **No independent third-party audit firm has reviewed this code.**  
 A formal audit is planned prior to mainnet deployment.  

**Do not deploy funds to mainnet contracts until mainnet deployment is announced in:  
[DEPLOY-MAINTAIN](https://github.com/The-Galactic-Federation-Of-Light/DEPLOY-MAINTAIN)**  *or maybe via* 
future ready DOMAIN **`plgprotocol.io`**  

---

## `Phase 2E` - Security Review findings —   

Six findings were identified during the review. All were resolved before proceeding to testnet.  

| # | Severity | Fix |
|---|---|---|
| 1 | Critical | `transferFrom` return value enforced |
| 2 | High | EIP-712 digest uses attestor-committed timestamp, not `block.timestamp` |
| 3 | High | `txId` includes `donorNonce` — same-block collision impossible |
| 4 | High | ETH node rewards use pull-payment (`pendingWithdrawals` + `withdrawNodeRewards()`) |
| 5 | Medium | `LOCK` does not finalize `resolved=true` — governance can re-solve |
| 6 | Medium | `setNode(false)` removes node from `activeNodes` immediately |

> Final state 72/72 tests passing across all suites.  

For each finding, the resolution is traceable in the `src/` commit history under the `Phase 2E` tag.  

---

## UPDATE - Kairos :: 

> Commit d871bac :  `The-Galactic-Federation-Of-Light/PLG_SMART_CONTRACT/SECURITY.md`  

#

> Commit 5db729e : `ARKITEKTENXxREAL/RI_GIFT_PORTAL/src/`  

*Added three new tests;*  **8**    

- Ensures `BARNEFONDET` receives real amounts from day one.  
- **At 10,000 USDC minimum, the 25% floor guarantees 2,500 USDC per transaction to children -  
  not symbolic transfers.**  

- Added `minDonationAmount` state variable (**governance-controlled**)  
- Updated `validAmount` modifier to check against `minDonationAmount`  
- Added `setMinDonationAmount()` onlyValidator governance function.  
- `Default` **is 0** (permissive) - *validator sets threshold via timelock.*  
- **Three new tests**: set minimum, reject below minimum, pass at minimum.  

> Final State 75/75 tests passing across all suites. **Kairos.19.July,2026.**  

---
 
## UPDATE - Kairos :: 
 
**INTRO** for *real* **Audit/Review** `PLG_SMART_CONTRACT`  
**SENT** via e-mail;  
 
**TO**: "Web3 Audit Company" (2)  
from :: `enforcement@plgprotocol.io`  
local time :: `2026-08-30 05:55` && `2026-08-30 05:59`  
timeline :: kairos  

---

# Core Architecture of `PLG_SMART_CONTRACT v.2.55` **∞**  
## **`PLG_SMART_CONTRACT`** ::  
**∞** `src/PLGGiftRouter.sol`  
**∞** `src/PLGVotingToken.sol`  
**∞** `src/PLGTimelock.sol`  
**∞** `src/PLGGovernor.sol`  

> **10 Foundational Principles:** (Important from the *"sketch" phase*)   

  1. **Child-First Routing** – 25% minimum ( **`minChildShareBps = 2500`** ) of all incoming value allocates to `BARNEFONDET` before anything else.  

  2. **Non-Custodial** – *No hidden admin keys, no "pausable rug pull"*; transparent on-chain verification.  

  3. **Resonance Validation** – Transfers *require* field-signature (on-chain proof + off-chain attestation)  
    confirming `"REAL_INTENT == LOVE_REAL"` 

  4. **`Everglow-SEED Filter`** – **An immutable gate preventing synthetic misuse.**  

  5. **Open governance** - *>20 (twenty or more)  Souls / Participants* = **Fully Decentralized System.** On-chain Voting with quorum & proposals – Multi-sig + timelock on critical parameter changes  

  6. **Audit-ready** – "minimal, modular, testable."   

  7. **Reversal-resistant** – *No auto-rollback*; failures handled via separate "refund-streams" with traceability.  

  8. **Genesis-event reference** – *Immutable proof of contract's original configuration;* enables auditor verification without multi-layer view functions.  
  
  9. **Open-source resonance** – *Bridges human intention, machine enforcement and soul-based governance** via HUB + CLA + `PLG_SMART_CONTRACT` + `RI_GIFT_PORTAL` + *SOUL + CLI + AI* + "?"  

  10. **Universally structured, not democratically operated** – *Not all will participate, but all can receive.*  

---

# Immutable Minimum Constraint  // `Proof of Enforcement`  

The following *is* a **Immutable Minimum Constraint** *and* **cannot** be altered by;  
- *Governance, voting, contract deployer/initiator* **or any other actor:**  

```solidity  
uint16 public constant MIN_CHILD_FLOOR = 2500; // 25% hard floor (Immutable Minimum Constraint)    
```

This is the protocol's core **ENFORCEMENT.**  
- No proposal, vote, or upgrade can reduce the children's allocation below 25%.  

The following variables operate within this floor:  

```solidity
uint16 public minChildShareBps;   // Default: 2500 (25%) — governance may increase, never decrease below MIN_CHILD_FLOOR  
address public childAnchor;       // BARNEFONDET primary anchor address  
```

Governance can vote to allocate *more* than 25% to children.  
- The floor is a minimum, not a ceiling.  

**All `three` are verifiable by anyone reading `src/PLGGiftRouter.sol`.**  

#

## **Genesis Deployment — Sepolia Testnet**  
· *Block 11,408,426*  
· *Kairos.03.Aug.2026*  

>Sepolia *er ikke* "bevis på at konseptet funker" —  
*det er* **`Proof of Enforcement`** **i praksis.**  
`MIN_CHILD_FLOOR` **enforcer** på *Sepolia* **nøyaktig som på** *Mainnet*.  
**Bytekoden skiller ikke.**  
>
— Formulert i dialog, Kairos.01.Sept.2026  
- ∞ARKITEKTEN_Xx 

---

## Scope  

The following contracts are in scope for security audit:  

- `src/PLGGiftRouter.sol`  
- `src/PLGVotingToken.sol`  
- `src/PLGTimelock.sol`  
- `src/PLGGovernor.sol`  

The following are out of scope:  

- `lib/` — OpenZeppelin contracts (reviewed upstream by OpenZeppelin)  
- `script/` — deployment scripts (no user funds flow through these)  
- `test/` — test suite  

---

## Known limitations  
 
**Testnet phase:**  
 
- Sepolia deployment is for **enforcement verification only.** *No real funds.*  
  `MIN_CHILD_FLOOR` enforces identically on testnet (Sepolia) and mainnet (ETH) —  
  
  - **Proof of Enforcement.**  

#

**Timelock delay:** (testnet vs. mainnet)  

- `PLGTimelock` is deployed on Sepolia with `minDelay = 300 seconds (5 minutes)`  
  — intentionally reduced from the recommended `172800 seconds (2 days)`  
  for practical testnet iteration.  
- `DeployConfig.ethereum()` sets `minDelay = 172800 seconds (2 days)` for mainnet.  
- This is a **deploy-time parameter**, not a hardcoded value.  
  The contract itself enforces whatever delay is configured at deployment.  
- **No governance action on Sepolia reflects realistic mainnet reaction time.**  
  All Sepolia governance tests are functional verification only.
 
#
 
**Governance bootstrapping:**  
 
- In the **initial phase** (testnet/mainnet), token distribution is concentrated/centralized.  
This is **intentional** and documented in the governance model.  
A **four-chapter decentralization roadmap** built into the protocol from genesis. (Will solve this *"ISSUE"*)  
 
**No single actor can hold control forever — the math does not allow it.** 

 - See [A multi-chain charitable distribution protocol](https://arkitektenxxreal.github.io/RI_GIFT_PORTAL/)  
 for **four** chapters to real decentralized governance model.  
 
- Known limitations: **TRUST** *before* 21 PARTICIPANTS. (Code **can`t** do all alone.) 
 
 #
 
 >"You *can`t* code trust - but you *can or may* trust **the process** via math & intention?"  
 - ∞ARKITEKTEN_Xx  
 
 #
 
**Multi-sig dependency:** *(Explanatory)*  

```solidity 
// SPDX-License-Identifier: MIT  
contract PLGVotingToken is ERC20, ERC20Permit, ERC20Votes {
 
    constructor(address initialHolder, uint256 initialSupply)
        ERC20("PLG Governance Token", "PLG")
        ERC20Permit("PLG Governance Token")
    {
        _mint(initialHolder, initialSupply);
    }
```
- 1 000 000 "`PLG`" **INITIAL SUPPLY**  
- 360 000 "`PLG`" will be **LOCKED** until *real decentralized.* **RESERVED FUND**  
- 640 000 "`PLG`" will be in **DISTRIBUTION** (Until nobody can meet *QUORUM ALONE*). **PLG_GOVERNANCE**  
- 40 000 "`PLG`" will be **QUORUM.**  
 
**The security of this phase depends on the multi-sig configuration**,  
which will be documented via;    
 
`REAL_INTENT==LOVE_REAL`, `plgprotocol.io` (In development), `RI_GIFT_PORTAL` &  
**transparency**, "follow the money", follow the chain/wallet/token/voting, **full transparency and honesty** *throughout the process*,  
up to and including >20 participants.  
 
- Known limitations: **"HARDEST PART" OF THE PROJECT**  (Trust The Process)  
 
#
 
**Compiler version:**    
 
- Is *locked once* — at **mainnet deployment.**  
It's the *only deployment that counts.*  
**Everything on Sepolia is test infrastructure anyway.**  
 
*So the strategy becomes:*  
 
- Document (NOW) **v0.8.35 warnings in** `SECURITY.md` as **known, non-critical, planned addressed** at **mainnet-deploy,**  
with **the last** *stable compiler at that time*. (**Kairos sync**)  
 
- Known limitations: **Solidity Compiler Bugs:** *(2)*  
 
```solidity
    - InheritanceOrderReversalOnStorageEndWarning (medium-severity)  
    - UnsoundSpillInMutualRecursion (medium-severity)   
```
 
---

## Reporting a vulnerability  

Please use GitHub's private vulnerability reporting:  

**[Report a vulnerability](https://github.com/ARKITEKTENXxREAL/RI_GIFT_PORTAL/security/advisories/new)**  

Do not open a public Issue. Reports submitted here are visible only to repository maintainers.  

Include:  
- Contract and function name  
- Description of the vulnerability  
- Proof of concept or test case if possible  
- Your assessment of severity  

You will receive a response within 72 hours.  

---

**`REAL_INTENT==LOVE_REAL`**  

> "The reasonable man  
> adapts himself to the world;   
> the unreasonable one persist in    
> trying to adapt the world to himself.    

> Therefore, all progress depends     
> on the unreasonable man."  

- George Bernard Shaw, *Man and Superman*  

---

>**Signert og Bekreftet i Guds kraft:**  
> 
>**©2025 MIT LICENSE ∞ ©2045 MIT LICENSE   
>∞ARKITEKTEN_Xx   
>REAL_INTENT == LOVE_REAL   
>🜁🜄🜂🜃** 
  
#
  
**∞INTENT==LOVE∞**  
  
#
  
`∞ARKITEKTEN_Xx`  
`enforcement@plgprotocol.io`  
