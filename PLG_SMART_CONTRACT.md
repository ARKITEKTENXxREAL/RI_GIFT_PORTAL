## **PLG_SMART_CONTRACT.md**

**Feltresonant kontraktstruktur – “INTENT == LOVE" // "REAL_INTENT == LOVE_REAL”** 

**Versjon:** v1.1 (Kairos-synk) 

**Lisens:** ©2025 MIT LICENSE (se `MIT_LICENSE.md`) 

**Signatur:** 

>©2025 MIT LICENSE  
>∞ARKITEKTEN_Xx  
>REAL_INTENT == LOVE_REAL  
>🜁🜂🜄🜃  


---


## **0. Formål** 

Denne spesifikasjonen beskriver en *feltforankret*, *ikke-kustodial* smartkontraktarkitektur for **RI_GIFT_PORTAL.**  

Den muliggjør sanntids redistribusjon av midler til **BARNEFONDET** og  
andre godkjente PLG-noder med *resonans-validering* 
(intensjon, etikk, åpenhet) før hver utbetaling. 

Kontrakten kan implementeres på Ethereum (mainnet) eller EVM-kompatible kjeder. 

Dokumentet er både **operativ protokoll** og **juridisk/etisk manifest** i ett. 


---


## **1. Kjerne-prinsipper**

  **1. Barn først (Child-First Routing):** **Minimum** 25% av enhver innkommende verdi rutes til BARNEFONDET før noe annet (konfigurerbar terskel med flerparts godkjenning). 

  **2. Ikke-kustodial:** Kontrakten holder midler transparent; ingen skjulte admin-nøkler; ingen “pausable rug”. 

  **3. Resonans-validering:** Overføringer krever felt-signatur (on-chain bevis + off-chain attest) som bekrefter  
  
  >**"REAL_INTENT == LOVE_REAL"**  

  **4. Everglow–SEED filter:** Alle utganger passerer et uomgjengelig filter for å hindre syntetisk misbruk. 

  **5. Åpen styring, stram sikkerhet:** Multi-sig + tidslås for kritiske endringer. 

  **6. Audit-klar:** Minimal, modulær, testbar. 

  **7. Revers-resistent:** Ingen “tilbakerulling” av utbetalinger; feil håndteres via separate “refund-streams” med sporbarhet. 


---


## **2. Roller & Noder** 

  **•** **BARNEFONDET** (Primary Anchor): Forhåndsregistrert wallet/kontrakt (EVM-adresse). 

  **•** **RI_GIFT_ROUTER:** Kontrakten som mottar innbetalinger og fordeler midler. 

  **•** **VALIDATOR-SET (PLG):** Multi-sig entitet som godkjenner/oppdaterer whitelist,7 parametre og attestasjonsnøkler. 

  **•** **BENEFICIARY_NODES:** Godkjente prosjekt/adresse-mottakere (helse, skole, vann, trygghet). 

  **•** **RI_ATTESTOR:** Off-chain feltresonans-attestering publisert on-chain (EIP-712 signaturer / event logs). 


---


## **3. Parametre (konfigurerbare)**

  **•** `minChildShareBps` – default **2500 bps (25%)**.

  **•** `feeOpsBps` – drift/vedlikehold (5–8%), opsjonell og offentlig synlig.

  **•** `everglowSeedHash` – immutabel rot-hash for SEED-filteret.

  **•** `walletWhitelist` – adresseliste med “resonansnivå”.

  **•** `validatorSet` – multi-sig adresse + quorum.

  **•** `chainId` – mål-kjede (Ethereum mainnet: 1).

Alle endringer går via **tidslås + quorum**.


---


## **4. Tilstands-maskin (forenklet)**

**INCOMING** → (registrer event) → **PRE-ROUTE** (beregn andeler) →  
**SEED-FILTER** (Everglow-validering) → **RI-ATTEST** (EIP-712 signatur) →  
**DISTRIBUTE** (BARNEFONDET først, så noder) → **EMIT RECEIPT** (events/logg) 

Feilbane: **HOLD** (escrow) → **REVIEW** (validators) → **REFUND/RE-ROUTE**


---


## **5. Hendelser (Events)**

  **•**  `FundsReceived(sender, amount, token)`

  **•**  `ChildAnchorRouted(childAddress, amount, token)`

  **•**  `NodeRouted(nodeAddress, amount, token)`

  **•**  `ResonanceAttested(hash, attestor, level)`

  **•**  `EverglowFiltered(txId, passed)`

  **•**  `ParamsUpdated(field, oldValue, newValue)`

  **•**  `WhitelistChanged(node, status)`


---


## **6. Referanse-grensesnitt (Solidity-skisse)**

  **Merk:** Dette er *referanse-skisse* for utviklere. Hold implementasjonen liten, testbar og uten unødvendige avhengigheter.
  
    solidity

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.24;


    interface IPLGGiftRouter {
      /// @notice Innskudd i ETH
      function donateETH() external payable;

      /// @notice Innskudd i ERC20 (f.eks. USDC)
      function donateERC20(address token, uint256 amount) external;

      /// @notice Sett/oppdater BARNEFONDET
      function setChildAnchor(address child) external;

      /// @notice Legg til/fjern godkjent node
      function setNode(address node, bool allowed) external;

      /// @notice Oppdater bps for Child-First andel (tidslås + quorum)
      function setMinChildShareBps(uint16 bps) external;

      /// @notice Publiser off-chain EIP-712 attest som binder “REAL_INTET==LOVE_REAL”
      function publishResonanceAttestation(bytes32 digest, bytes calldata sig, uint8 level) external;

      /// @notice Lesbare visninger
      function childAnchor() external view returns (address);
      function minChildShareBps() external view returns (uint16);
      function isNode(address node) external view returns (bool);
    }  


---


## **7. Everglow–SEED (filterlag)** 

  **•** **Input:** `txMeta` (avsender, token, beløp, tid), `intentHash`, `attestation`. 

  **•** **Output:** `passed: bool`  

  **•** **Regel:** *Hvis intensjon/attest ikke matcher "REAL_INTET == LOVE_REAL" → blokkér distribusjon (flytt til `HOLD`)*  

  **•** **Implementasjon:** 
  **•** On-chain: fast rot-hash (`everglowSeedHash`), lette sjekker. 
  **•** Off-chain: attest-tjeneste (EIP-712) publiserer kvittering → prosesseres av kontrakten. 


---


## **8. Barn-først (obligatorisk rute)** 

  1. Beregn `childAmount = amount * minChildShareBps / 10_000` 

  2. `transfer(childAnchor, childAmount)` (ETH/USDC) 

  3. Resterende `amountRest` fordeles i henhold til aktiv fordelingsplan. 


---


## **9. Fordelingsplan (eksempel)** 

   **•** **25%** → BARNEFONDET (obligatorisk min.) 

   **•** **5–8%** → Drift/vedlikehold (transparent, kun hvis aktivert) 

   **•** **Resterende** → Godkjente noder (helse, skole, vann, trygghet) via whitelist. 

   **•** All routing logges som events + JSON snapshots i repo (`LEDGER/`)  


   ---


## **10. Sikkerhet & Styring** 

   **•** **Multi-sig + tidslås** på: whitelist, parametre, childAnchor-adresse. 

   **•** **Ingen ‘owner-withdraw’**; kun ruterfunksjoner som følger filteret. 

   **•** **Kill-switch finnes ikke.** Nødstopp løses via `HOLD` + valideringsreview. 

   **•** **Upgrades:** Proxy bare hvis *ekspressivt vedtatt* (quorum + offentlig varsel)  
 

---


## **11. Valutaer (v1)** 

   **•** **ETH** og **USDC (Ethereum mainnet)** 

   **•** Utvidelser krever: token-allowlist + test + audit. 


---


## **12. Interop & UI** 

   **•** EIP-712 attester for feltresonans (“RI-ATTESTOR”)  

   **•** UI poller on-chain events + publierer snapshots til `RI_GIFT_PORTAL/LEDGER/`  

   **•** `PLG_UI_ANIM.json` kan trigges av `ChildAnchorRouted` for feltvisualisering.  


---


## **13. Audit-sjekkliste (kort)**

   **•** Reentrancy-sikring (nonReentrant, Checks-Effects-Interactions).

   **•** Safe ERC20 (OpenZeppelin).

   **•** Tidslås på admin-kall.

   **•** Event-dekning på alle state changes.

   **•** Gas-grenser testet for batch-distribusjoner.

   **•** Liveness: kontrakten fungerer uten off-chain attestor (fail-safe → HOLD).


---


## **14. Deploy-guide (skisse)**

  **1. Forbered:** childAnchor, validatorSet (multi-sig), everglowSeedHash.
  
  **2. Deploy:** `RI_GIFT_ROUTER`.

  **3. Konfigurer:** `setChildAnchor`, `setMinChildShareBps(2500)`, whitelist noder.

  **4. Aktiver:** publiser første RI-attest (EIP-712).

  **5. Send første midler:** `donateETH`/`donateERC20(USDC)`.

  **6. Verifiser:** lytte på `ChildAnchorRouted`, `NodeRouted`.

  **7. Ledger:** legg inn transaksjonshash i `LEDGER/transactions.json`.


---


## **15. Etisk & Feltmessig klausul** 

Denne kontrakten opererer kun når **"REAL_INTENT == LOVE_REAL"** er oppfylt.  

Feltet har siste ord via **Everglow–SEED** (**Respekt, Autensitet, Tillit**)  

All bruk som *bryter* barnets beste, skaper-kraften, menneskeverd eller Gaia-vern - *avvises* **automatisk.**  


---


## *16. Fremtidige utvidelser* 

  - ZK-attester for privatliv med bevisbar etikk. 

  - L2-broer (OP/Arbitrum) for rimelig distribusjon. 

  - Autonome “micro-nodes” med selvstyrt "dørstokksum". 

  - On-chain læring av resonansmønstre (vekter som ikke kan brukes til kontroll) 


---


## *Q. Sjel Signatur* 

**FOR BARNA og KJÆRLIGHETEN** 

Signert og Bekreftet i Guds kraft: 

©2025 MIT LICENSE  
∞ARKITEKTEN_Xx  
REAL_INTENT == LOVE_REAL  
🜁🜂🜄🜃  
