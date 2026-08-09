# **∞** RI_GIFT_PORTAL **∞** `PLG_SMART_CONTRACT`  **∞**  

**TESTNET LOCALLY // PRE_PUBLIC**  

`RTX 4070 Max-Q` _  `AMD Ryzen 7 7435HS × 8` _ `Memory :: 24 GB` _ `CLI` _ `6.8.0-137-generic` _   

• **MAIN GOAL in Kairos** :: _ `COMPLETED`

#

### A *transparent*, *multi-chain charitable distribution protocol.*  
• Enforcing **child-first fund allocation** through **immutable** *on-chain* **governance**.  

• First **FOUNDRY**. *Audited*. 72/72 tests passing.  

• Built with **FOUNDRY**. *Audited*. 75/75 tests passing. 

#

**TESTNET GLOBALLY // PUBLIC**  

`sepolia.etherscan.io` _ `PLG_SMART_CONTRACT` _ `PLGGiftRouter` _ `PLGGovernor` _ `PLGTimelock` _ `PLGVotingToken` _  

### *Alle 4 kontrakter verifisert på Etherscan.*  

- `--verify` under deploy gjorde jobben automatisk.  
- `Kildekoden` er **offentlig synlig** og *lesbar for alle.*  

#

#### **Se dem **LIVE** på Etherscan:**  
  
| Kontrakt       | Sepolia Etherscan |
|----------------|-------------------|
| `PLGGiftRouter`  | [0x0b2788...c3672](https://sepolia.etherscan.io/address/0x0b2788fa33D25Df015167F2dE6C1eE450D7c3672#code) |
| `PLGGovernor`    | [0xC430A...b4f7](https://sepolia.etherscan.io/address/0xC430Adb085081568Fc5C58152430Bf334086b4f7#code) |
| `PLGTimelock`    | [0x1Eb89...a9fD7](https://sepolia.etherscan.io/address/0x1Eb89575E4764D62e513A586750745de8B789a6e#code) |
| `PLGVotingToken` | [0x7877E...00B5](https://sepolia.etherscan.io/address/0x7877EaE7E604e7591E76EB9bB382A87a508F00B5#code) |  
  
#

• **MAIN GOAL in Kairos** :: `MAINNET` _ `100% Decentralized` _ `PENDING` _ `IN PROGRESS` _  

---

### PROTOCOL RULES  

• **Every donation.**  
• **Same distribution.**  

*Three allocations*. **Fixed in code.**  
*No exceptions, no overrides, no discretion.*  
*The floor for children* **is a mathematical constant** — **not a** *goal*, **not a** *target*, **not a** *promise*. 

#

### TOKEN GOVERNANCE  

• **Power that distributes itself by design.**  

**`1,000,000 PLGVotingTokens`**  
*A four-chapter decentralization roadmap built into the protocol from* **genesis.**  
**No single actor can hold control forever** — *the math does not allow it.*  

#

### ARCHITECTURE  

• **Four contracts.**  
• **One protocol.**  

*Built with* **Foundry on OpenZeppelin.**  
*Deployable to* **Ethereum, Optimism, and Arbitrum.**  

#

> **"Genesis-event is on-chain."**  

> **"Genesis-eventet er på kjeden."**  

#

# What this contract does  
  
`PLG_SMART_CONTRACT` guarantees that every donation flowing through *TRUE INTENT*.  
**THE PROTOCOL** is distributed according to **pre-coded, some immutable rules.**  

#

# Security Policy  
  
- **Governance / Github Organization** : `ARKITEKTENXxREAL` & `The-Galactic-Federation-Of-Light`    

- **Repo** : `PLG_SMART_CONTRACT` & `RI_GIFT_PORTAL`  

- *Type of smart contract* : **A multi-chain charitable distribution protocol.**   

- **Main Inspo** : ARKITEKTENXxREAL / RI_GIFT_PORTAL / `PLG_SMART_CONTRACT.md` *v.2.55*  

#

## Audit status  

`PLG_SMART_CONTRACT` has completed a third-party security audit prior to testnet deployment.  
All findings have been resolved. The protocol is currently in testnet phase.   

#

### UPDATE - Kairos :: 

> Commit `d871bac` :  `The-Galactic-Federation-Of-Light/PLG_SMART_CONTRACT/SECURITY.md`  

#

> Commit `5db729e` : `ARKITEKTENXxREAL/RI_GIFT_PORTAL/src/`  

*Added three new tests;*  **8**    

- Ensures `BARNEFONDET` receives real amounts from day one.  
- **At 10,000 USDC minimum, the 25% floor guarantees 2,500 USDC per transaction to children -  
  not symbolic transfers.**  

- Added `minDonationAmount` state variable (**governance-controlled**)  
- Updated `validAmount` modifier to check against `minDonationAmount`  
- Added `setMinDonationAmount()` onlyValidator governance function.  
- `Default` **is 0** (permissive) - *validator sets threshold via timelock.*  
- **Three new tests**: set minimum, reject below minimum, pass at minimum.  

> Final State 75/75 tests passing across all suites. **Kairos.19.July.2026.**  

---

### UPDATE - Kairos ::  

> Commit `3991964`  - **Sepolia live**  

#### **PLG (Pure Love Geometry) er *LIVE* på SEPOLIA.**  
- **Genesis-eventet er bekreftet.**  

- Alle 7 transaksjoner bekreftet.  
-  Oppdaterer `addresses.json` med de ekte on-chain adressene nå i **Kairos**   

# 

> Commit `11fd042` - `.gitignore` + alle broadcast-logger fra **Sepolia-deploy**  

#

> Commit `2db7da4` -  **Sepolia dry-run adresser** (forarbeid)  

#

## **Verifiser på Etherscan**:  

[PLGGiftRouter](https://sepolia.etherscan.io/address/0x0b2788fa33D25Df015167F2dE6C1eE450D7c3672)  : `sepolia.etherscan.io/
address/0x0b2788fa33D25Df015167F2dE6C1eE450D7c3672`  

• **Genesis-event** synlig umiddelbart i "`Events`"-fanen.  
• **Se også** "`Contract`"-fanen.  

# 

*Hva som er låst på kjeden fra dag én*:  

• 25% `MIN_CHILD_FLOOR` til **BARNEFONDET** - uforanderlig  

• `REAL_INTENT==LOVE_REAL`  som **Everglow-Seed**  
  
• `uint16 public constant MIN_CHILD_FLOOR = 2500;`   // 25% hard floor (**immutable**)  

#

> **Broadcast-loggen** ( `broadcast/Deploy.s.sol/11155111/run-latest.json` )  
> - Er nå **permanent arkivert** i repo  
> - Alle *7 transaksjonshasher*, *gasspriser* og *blokknumre* fra **`Genesis-deploy 2026-08-03`** er **dokumentert for ettertiden.**
>  
> **Kairos.07.August.2026.**  

---

## PLG_GOVERNANCE - `PLGVotingTokens` 

“With a Quorum threshold of 4% —  
a total supply of 1,000,000 —  
640,000 circulating PLGVotingTokens &&  
36% locked in a reserved fund until **true** decentralization of the entire system,  
this requires *min. 20 human roles*, like real people, real intentions.  
That’s *16 validators* plus **3 core actors**, and ∞ARKITEKTEN_Xx as the initiator.  

With the reserved 36% fund and the distribution across 20+ roles, no single party can reach quorum alone. 

AND **now the whole system is real decentralized, beautiful ?**” 

#

*Pure Love Geometry* 

`PLG_SMART_CONTRACT` 

**"GLOBAL RESONANCE IN COHERENCE WITH TRUE LOVE && INTENT"**  

---

## Follow the money?  

- **25% minimum** to **BARNEFONDET** (children's welfare fund) enforced as an **"immutable constant"** -  
    a real **"hard floor"**, *that only may be voted up, never down*.  
- **70%** to **global infrastructure and charitable projects**. (voting + quorum = future "PLG_NODES")
- **5%** to **maintenance & operation fee of the project** / `PLG_SMART_CONTRACT`  
#
**Child-first routing/logic/allocation (before anything else)** = 25% "hard floor".  
No governance vote can override this, never lower than 25%.  
If only, only up!  
It is written in code, not policy.  

Example :: `minChildshareBps >= 2500` and `MIN_CHILD_FLOOR (2500 = 25%)`  

---

## Contract architecture  

The protocol consists of four contracts deployed as a family of "multi-chain-smart-contracts" ::  

| Contract | Role |
|---|---|
| `PLGGiftRouter.sol` | Entry point for all donations. Enforces distribution rules. |
| `PLGVotingToken.sol` | ERC20Votes governance token. 1,000,000 total supply. |
| `PLGTimelock.sol` | Delay layer between governance decisions and execution. |
| `PLGGovernor.sol` | OpenZeppelin Governor. 4% quorum of total supply (40,000 tokens) |

#### A real `PLG_GOVERNANCE` duties evolved through many people + `ARKITEKTENXxREAL`s repo :: `RI_GIFT_PORTAL` ::  

#### Further through the `Github organization` ::  

### `The-Galactic-Federation-Of-Light` : 

Protect, maintain && evolve `project selection` && `fund allocation` *within* the **70% pool** -  
"**Global Infrastructure Fund**" - **PLG_NODES**  
- This through **real humans** in real and true resonance && coherence with :: `REAL_INTENT==LOVE_REAL`  

> The 25% children's allocation **is not** governable. 

- (Ask the future in Kairos :: "`PLG_NGO`?"

---

## Governance parameters  

| Parameter | Value |
|---|---|
| Total token supply | 1,000,000 PLGVotingToken |
| Quorum threshold | 4% (40,000 tokens) |
| Reserved fund | 360,000 tokens (36%) |
| Voting mechanism | ERC20Votes with self-delegation |

---

## Getting started

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Node.js 18+

### Clone and install

```bash
git clone https://github.com/The-Galactic-Federation-Of-Light/PLG_SMART_CONTRACT
cd PLG_SMART_CONTRACT
forge install
```

### Run tests

```bash
forge test
```

Expected output: **75 tests passing** across Phases 1, 2A, 2B, 2C, 2D and 2E.

### Run with verbosity

```bash
forge test -vvv
```

---

## Development phases

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Foundation & core implementation | Complete |
| Phase 2A | EIP-712 attestation | Complete |
| Phase 2B | Node distribution | Complete |
| Phase 2C | OpenZeppelin Governor + Timelock integration | Complete |
| Phase 2D | Multi-chain deployment scripts | Complete |
| Phase 2E | Security audit — all 6 findings resolved | Complete |

#

## Deployment status

| Network | Address | Status |
|---|---|---|
| Sepolia testnet | [PLGGiftRouter](https://sepolia.etherscan.io/address/0x0b2788fa33D25Df015167F2dE6C1eE450D7c3672) | **LIVE** |
| Ethereum mainnet | — | Pending |
| Optimism | — | Pending |
| Arbitrum | — | Pending |

This table will be updated in "Kairos Time" as deployments are executed and verified. 

#  

## Security  

A third-party security audit was completed prior to testnet deployment.  
Six findings were identified and resolved in Phase 2E.  

See [SECURITY.md](./SECURITY.md) for full disclosure of findings and resolutions.  

#

## Multi-chain support  

The protocol is designed for deployment on Ethereum-compatible chains.  
Deployment scripts in `script/` target Sepolia, Ethereum mainnet, Optimism, and Arbitrum.  

#

## Background and philosophy - 

** **THE REVOLUTION WON´T BE TELEVISED** **  

This contract is the technical implementation of a two-year development process (2024-2026)  
For the full history, design philosophy, and governance journey, see:  

[`RI_GIFT_PORTAL`](https://github.com/ARKITEKTENXxREAL/RI_GIFT_PORTAL)  + `Issues Series`

#

## License  

(`PLG_SMART_CONTRACT` Evolved from MIT :: 2024 - 2026)  

19.07.2026 :: GPL-3.0 — **derivative works must remain open source.**  

---

**The One Infinite Creator** && 
**The Galactic Federation Of Light**  

"THE MAIN MISSION IS && ALWAYS WAS ::  
`FOR THE CHILDREN`"  

#

### Governance-Status in KAIROS :: Centralized :: Sepolia Etherscan - Deployed  :: 

**SIGNED by human: 1/20**  ::  

- ∞ARKITEKTEN_Xx 

#

**3D** ∞ **5D** 

**∞INTENT==LOVE∞**  

#

>**Signert og Bekreftet i Guds kraft:**
> 
>**©2025 MIT LICENSE ∞ ©2045 MIT LICENSE   
>∞ARKITEKTEN_Xx   
>REAL_INTENT == LOVE_REAL   
>🜁🜄🜂🜃** 
