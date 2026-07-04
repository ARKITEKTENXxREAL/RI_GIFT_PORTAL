// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// EIP-712 Attestation Struct
struct ResonanceAttestation {
    bytes32 txId;
    address donor;
    uint256 amount;
    address token;
    bytes32 intentHash;
    uint256 timestamp;
    uint8 level;
}

/**
 * @title PLGGiftRouter
 * @notice Feltresonant, non-kustodial smartkontrakt for RI_GIFT_PORTAL
 * @dev Distributes value with child-first routing, resonance validation, and transparent governance
 * 
 * PLG_SMART_CONTRACT.md v2.55 (Kairos-synk)
 * Signert og Bekreftet i Guds kraft:
 * ©2025 MIT LICENSE ∞ ©2045 MIT LICENSE
 * ∞ARKITEKTEN_Xx
 * REAL_INTENT == LOVE_REAL
 * 🜁🜂🜄🜃
 */
contract PLGGiftRouter {

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTANTS (Immutable - Hard boundaries)
    // ═══════════════════════════════════════════════════════════════════════════

    uint16 public constant MAX_BPS = 10000;           // 100% in basis points
    uint16 public constant MIN_CHILD_FLOOR = 2500;   // 25% hard floor (immutable)
    uint16 public constant MAX_FEE_CAP = 1000;       // 10% max fee (immutable safety cap)

    // EIP-712 Type Hash for ResonanceAttestation
    bytes32 public constant RESONANCE_ATTESTATION_TYPEHASH =
        keccak256("ResonanceAttestation(bytes32 txId,address donor,uint256 amount,address token,bytes32 intentHash,uint256 timestamp,uint8 level)");
    
    bytes32 private DOMAIN_SEPARATOR;
    string public constant EIP712_VERSION = "1";

    // ═══════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES (Governance-controlled via multi-sig + timelock)
    // ═══════════════════════════════════════════════════════════════════════════

    uint16 public minChildShareBps;                  // Default: 2500 (25%)
    uint16 public feeOpsBps;                         // Default: 500-800 (5-8%)
    bytes32 public everglowSeedHash;                 // Root hash for SEED filter
    bytes32 public walletWhitelistHash;              // Hash of approved nodes
    address public childAnchor;                      // BARNEFONDET primary anchor
    address public validatorSet;                     // Multi-sig governance entity
    uint256 public chainId;                          // Target chain (e.g., 1 for Ethereum)
    address public operationsWallet;                 // Operations fee recipient

    mapping(address => bool) public isNode;          // Fast lookup: is node whitelisted?
    mapping(address => bool) public isAttestor;      // Fast lookup: is attestor approved?
    mapping(bytes32 => HeldFunds) public held;       // Escrow for held funds during review
    mapping(bytes32 => bool) public usedNonces;      // Prevent replay attacks: attestation nonce used?

    // ═══════════════════════════════════════════════════════════════════════════
    // STRUCTS
    // ═══════════════════════════════════════════════════════════════════════════

    struct HeldFunds {
        address donor;
        uint256 amount;
        address token;
        uint256 timestamp;
        string reason;
        bool resolved;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════

    event Genesis(
        uint16 indexed minChildShareBps,
        uint16 indexed feeOpsBps,
        bytes32 everglowSeedHash,
        bytes32 walletWhitelistHash,
        address indexed validatorSet,
        uint256 chainId
    );

    event FundsReceived(
        address indexed sender,
        uint256 amount,
        address indexed token,
        bytes32 indexed intentHash
    );

    event ChildAnchorRouted(
        address indexed childAddress,
        uint256 amount,
        address indexed token,
        bytes32 indexed transactionId
    );

    event ChildShareTooSmall(
        address indexed sender,
        uint256 amount,
        address indexed token
    );

    event NodeRouted(
        address indexed nodeAddress,
        uint256 amount,
        address indexed token,
        bytes32 indexed transactionId
    );

    event ResonanceAttested(
        bytes32 indexed hash,
        address indexed attestor,
        uint8 level
    );

    event EverglowFiltered(
        bytes32 indexed txId,
        bool passed,
        string reason
    );

    event ParamsUpdated(
        string indexed field,
        uint256 oldValue,
        uint256 newValue
    );

    event WhitelistChanged(
        address indexed node,
        bool status
    );

    event AttestorChanged(
        address indexed attestor,
        bool status
    );

    event FundsHeld(
        bytes32 indexed txId,
        address indexed donor,
        uint256 amount,
        string reason
    );

    event ReviewStarted(
        bytes32 indexed txId,
        address indexed reviewInitiator
    );

    event Resolved(
        bytes32 indexed txId,
        string resolution,
        address indexed target
    );

    event OperationsFunded(
        address indexed operationsWallet,
        uint256 amount,
        address indexed token
    );

    // ═══════════════════════════════════════════════════════════════════════════
    // MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════

    modifier onlyValidator() {
        require(msg.sender == validatorSet, "Only validator set can call");
        _;
    }

    modifier onlyApprovedAttestor() {
        require(isAttestor[msg.sender], "Only approved attestor can call");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(
        uint16 _minChildShareBps,
        uint16 _feeOpsBps,
        bytes32 _everglowSeedHash,
        bytes32 _walletWhitelistHash,
        address _childAnchor,
        address _validatorSet,
        address _operationsWallet,
        uint256 _chainId
    ) {
        // ─ Chain verification ─
        require(_chainId == block.chainid, "Wrong chain");

        // ─ Required addresses ─
        require(_childAnchor != address(0), "Invalid child anchor");
        require(_validatorSet != address(0), "Invalid validator");
        require(_operationsWallet != address(0), "Invalid operations wallet");

        // ─ Seed hash must be set ─
        require(_everglowSeedHash != bytes32(0), "Invalid seed hash");

        // ─ Child-first hard floor enforcement ─
        require(
            _minChildShareBps >= MIN_CHILD_FLOOR,
            "Child share below floor (min 2500 bps)"
        );

        // ─ Fee cap protection ─
        require(_feeOpsBps <= MAX_FEE_CAP, "Fee exceeds cap (max 1000 bps)");

        // ─ Total allocation cannot exceed 100% ─
        require(
            uint256(_minChildShareBps) + uint256(_feeOpsBps) <= MAX_BPS,
            "Total BPS exceeds 100%"
        );

        // ─ Set state ─
        minChildShareBps = _minChildShareBps;
        feeOpsBps = _feeOpsBps;
        everglowSeedHash = _everglowSeedHash;
        walletWhitelistHash = _walletWhitelistHash;
        childAnchor = _childAnchor;
        validatorSet = _validatorSet;
        operationsWallet = _operationsWallet;
        chainId = _chainId;

        // ─ Initialize EIP-712 Domain Separator ─
        DOMAIN_SEPARATOR = _computeDomainSeparator();

        // ─ Emit Genesis event (immutable baseline) ─
        emit Genesis(
            _minChildShareBps,
            _feeOpsBps,
            _everglowSeedHash,
            _walletWhitelistHash,
            _validatorSet,
            _chainId
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CORE DONATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Donate ETH with optional intent hash and attestation
     * @param _intentHash Intent hash for SEED filter validation
     * @param _attestation Off-chain resonance attestation signature
     */
    function donateETH(
        bytes32 _intentHash,
        bytes calldata _attestation
    ) external payable validAmount(msg.value) {
        _processDonation(
            msg.value,
            address(0),
            _intentHash,
            _attestation
        );
    }

    /**
     * @notice Donate ERC20 token with optional intent hash and attestation
     * @param _token ERC20 token address
     * @param _amount Amount to donate
     * @param _intentHash Intent hash for SEED filter validation
     * @param _attestation Off-chain resonance attestation signature
     */
    function donateERC20(
        address _token,
        uint256 _amount,
        bytes32 _intentHash,
        bytes calldata _attestation
    ) external validAmount(_amount) {
        // Transfer tokens from donor to this contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        _processDonation(
            _amount,
            _token,
            _intentHash,
            _attestation
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INTERNAL PROCESSING
    // ═══════════════════════════════════════════════════════════════════════════

    function _processDonation(
        uint256 _amount,
        address _token,
        bytes32 _intentHash,
        bytes calldata _attestation
    ) internal {
        bytes32 txId = keccak256(
            abi.encodePacked(
                msg.sender,
                _amount,
                _token,
                block.timestamp,
                block.number
            )
        );

        // ─ PRE-ROUTE: Calculate shares ─
        uint256 childAmount = (_amount * minChildShareBps) / MAX_BPS;
        uint256 feeAmount = (_amount * feeOpsBps) / MAX_BPS;
        uint256 remainingAmount = _amount - childAmount - feeAmount;

        // ─ Dust protection ─
        if (childAmount == 0) {
            emit ChildShareTooSmall(msg.sender, _amount, _token);
            revert("Child share too small");
        }

        // ─ SEED-FILTER: Validate intent ─
        bool seedPassed = _validateSeedFilter(
            txId,
            _intentHash,
            msg.sender,
            _amount,
            _token,
            _attestation
        );
        if (!seedPassed) {
            _holdFunds(txId, msg.sender, _amount, _token, "SEED filter validation failed");
            emit EverglowFiltered(txId, false, "Intent validation failed");
            return;
        }

        emit EverglowFiltered(txId, true, "Intent validated");

        // ─ RI-ATTEST: Verify off-chain attestation ─
        // (In production, this would verify EIP-712 signatures)
        // For now, assume attestation is valid if SEED filter passed

        // ─ DISTRIBUTE: Route funds ─
        _distribute(txId, childAmount, feeAmount, remainingAmount, _token);

        emit FundsReceived(msg.sender, _amount, _token, _intentHash);
    }

    function _validateSeedFilter(
        bytes32 _txId,
        bytes32 _intentHash,
        address _donor,
        uint256 _amount,
        address _token,
        bytes calldata _attestation
    ) internal returns (bool) {
        // ─ Check: Intent hash is present ─
        if (_intentHash == bytes32(0)) {
            return false;
        }

        // ─ Check: Attestation is present (non-empty) ─
        if (_attestation.length == 0) {
            return false;
        }

        // ─ Check: Attestation is valid EIP-712 signature ─
        if (_attestation.length != 65) {
            return false;
        }

        // ─ Recover attestor address from signature ─
        address attestor = _recoverAttestor(
            _txId,
            _donor,
            _amount,
            _token,
            _intentHash,
            _attestation
        );

        // ─ Check: Recovered address is approved attestor ─
        if (!isAttestor[attestor]) {
            return false;
        }

        // ─ Check: Nonce not already used (replay protection) ─
        if (usedNonces[_txId]) {
            return false;
        }

        // ─ Mark nonce as used ─
        usedNonces[_txId] = true;

        return true;
    }

    function _recoverAttestor(
        bytes32 _txId,
        address _donor,
        uint256 _amount,
        address _token,
        bytes32 _intentHash,
        bytes calldata _signature
    ) internal view returns (address) {
        bytes32 digest = _hashResonanceAttestation(
            _txId,
            _donor,
            _amount,
            _token,
            _intentHash
        );

        // ─ Recover signer from signature ─
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(_signature);
        return ecrecover(digest, v, r, s);
    }

    function _hashResonanceAttestation(
        bytes32 _txId,
        address _donor,
        uint256 _amount,
        address _token,
        bytes32 _intentHash
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(
            RESONANCE_ATTESTATION_TYPEHASH,
            _txId,
            _donor,
            _amount,
            _token,
            _intentHash,
            block.timestamp,
            uint8(1)  // level: 1 for verified
        ));

        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));
    }

    function _splitSignature(bytes calldata _signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(_signature.length == 65, "Invalid signature length");

        assembly {
            let offset := _signature.offset
            r := calldataload(offset)
            s := calldataload(add(offset, 32))
            v := byte(0, calldataload(add(offset, 64)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature v value");
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        return keccak256(abi.encode(
            typeHash,
            keccak256(bytes("PLGGiftRouter")),
            keccak256(bytes(EIP712_VERSION)),
            block.chainid,
            address(this)
        ));
    }

    function _distribute(
        bytes32 _txId,
        uint256 _childAmount,
        uint256 _feeAmount,
        uint256 _remainingAmount,
        address _token
    ) internal {
        // ─ Route to BARNEFONDET (child-first) ─
        if (_token == address(0)) {
            (bool success,) = childAnchor.call{value: _childAmount}("");
            require(success, "ETH transfer to child failed");
        } else {
            require(IERC20(_token).transfer(childAnchor, _childAmount), "Transfer failed");
        }
        emit ChildAnchorRouted(childAnchor, _childAmount, _token, _txId);

        // ─ Route to operations (if enabled) ─
        if (_feeAmount > 0) {
            if (_token == address(0)) {
                (bool success,) = operationsWallet.call{value: _feeAmount}("");
                require(success, "ETH transfer to ops failed");
            } else {
                require(IERC20(_token).transfer(operationsWallet, _feeAmount), "Transfer failed");
            }
            emit OperationsFunded(operationsWallet, _feeAmount, _token);
        }

        // ─ Route remaining to whitelisted nodes ─
        // (In production: distribute proportionally to nodes based on whitelist)
        // For MVP: send remainder to child anchor as well
        if (_remainingAmount > 0) {
            if (_token == address(0)) {
                (bool success,) = childAnchor.call{value: _remainingAmount}("");
                require(success, "ETH transfer failed");
            } else {
                require(IERC20(_token).transfer(childAnchor, _remainingAmount), "Transfer failed");
            }
            emit NodeRouted(childAnchor, _remainingAmount, _token, _txId);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FEILBANE (ERROR PATH): HOLD, REVIEW, RESOLVE
    // ═══════════════════════════════════════════════════════════════════════════

    function _holdFunds(
        bytes32 _txId,
        address _donor,
        uint256 _amount,
        address _token,
        string memory _reason
    ) internal {
        held[_txId] = HeldFunds({
            donor: _donor,
            amount: _amount,
            token: _token,
            timestamp: block.timestamp,
            reason: _reason,
            resolved: false
        });
        emit FundsHeld(_txId, _donor, _amount, _reason);
    }

    function initiateReview(bytes32 _txId) external onlyValidator {
        require(held[_txId].amount > 0, "No held funds for this transaction");
        require(!held[_txId].resolved, "Already resolved");
        emit ReviewStarted(_txId, msg.sender);
    }

    function resolveHold(
        bytes32 _txId,
        string memory _resolution,
        address _target
    ) external onlyValidator {
        HeldFunds storage holdRecord = held[_txId];
        require(holdRecord.amount > 0, "No held funds");
        require(!holdRecord.resolved, "Already resolved");

        holdRecord.resolved = true;

        if (keccak256(abi.encodePacked(_resolution)) == keccak256(abi.encodePacked("REFUND"))) {
            // Return funds to donor
            if (holdRecord.token == address(0)) {
                (bool success,) = holdRecord.donor.call{value: holdRecord.amount}("");
                require(success, "ETH refund failed");
            } else {
                require(IERC20(holdRecord.token).transfer(holdRecord.donor, holdRecord.amount), "Transfer failed");
            }
        } else if (keccak256(abi.encodePacked(_resolution)) == keccak256(abi.encodePacked("DONATE_TO_CHILD"))) {
            // Send to BARNEFONDET
            if (holdRecord.token == address(0)) {
                (bool success,) = childAnchor.call{value: holdRecord.amount}("");
                require(success, "ETH donation failed");
            } else {
                require(IERC20(holdRecord.token).transfer(childAnchor, holdRecord.amount), "Transfer failed");
            }
        } else if (keccak256(abi.encodePacked(_resolution)) == keccak256(abi.encodePacked("REROUTE"))) {
            // Send to validator-approved target
            require(_target != address(0), "Invalid target for reroute");
            if (holdRecord.token == address(0)) {
                (bool success,) = _target.call{value: holdRecord.amount}("");
                require(success, "ETH reroute failed");
            } else {
                require(IERC20(holdRecord.token).transfer(_target, holdRecord.amount), "Transfer failed");
            }
        }
        // else: LOCK (do nothing, funds remain held)

        emit Resolved(_txId, _resolution, _target);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GOVERNANCE FUNCTIONS (Multi-sig + Timelock in production)
    // ═══════════════════════════════════════════════════════════════════════════

    function setChildAnchor(address _newChildAnchor) external onlyValidator {
        require(_newChildAnchor != address(0), "Invalid address");
        address _oldAnchor = childAnchor;
        childAnchor = _newChildAnchor;
        emit ParamsUpdated(
            "childAnchor",
            uint256(uint160(_oldAnchor)),
            uint256(uint160(_newChildAnchor))
        );
    }

    function setOperationsWallet(address _newWallet) external onlyValidator {
        require(_newWallet != address(0), "Invalid address");
        address _oldWallet = operationsWallet;
        operationsWallet = _newWallet;
        emit ParamsUpdated(
            "operationsWallet",
            uint256(uint160(_oldWallet)),
            uint256(uint160(_newWallet))
        );
    }

    function setMinChildShareBps(uint16 _newBps) external onlyValidator {
        require(_newBps >= MIN_CHILD_FLOOR, "Cannot lower below hard floor");
        require(_newBps <= MAX_BPS, "Invalid BPS");
        uint256 _oldBps = minChildShareBps;
        minChildShareBps = _newBps;
        emit ParamsUpdated("minChildShareBps", _oldBps, _newBps);
    }

    function setFeeOpsBps(uint16 _newBps) external onlyValidator {
        require(_newBps <= MAX_FEE_CAP, "Exceeds fee cap");
        uint256 _oldBps = feeOpsBps;
        feeOpsBps = _newBps;
        emit ParamsUpdated("feeOpsBps", _oldBps, _newBps);
    }

    function setNode(address _node, bool _approved) external onlyValidator {
        require(_node != address(0), "Invalid node address");
        isNode[_node] = _approved;
        emit WhitelistChanged(_node, _approved);
    }

    function setAttestor(address _attestor, bool _approved) external onlyValidator {
        require(_attestor != address(0), "Invalid attestor address");
        isAttestor[_attestor] = _approved;
        emit AttestorChanged(_attestor, _approved);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function getHeldFunds(bytes32 _txId) external view returns (HeldFunds memory) {
        return held[_txId];
    }

    function calculateDistribution(uint256 _amount)
        external
        view
        returns (
            uint256 childShare,
            uint256 feeShare,
            uint256 remainingShare
        )
    {
        childShare = (_amount * minChildShareBps) / MAX_BPS;
        feeShare = (_amount * feeOpsBps) / MAX_BPS;
        remainingShare = _amount - childShare - feeShare;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // RECEIVE (for direct ETH transfers)
    // ═══════════════════════════════════════════════════════════════════════════

    receive() external payable {
        // Accept ETH without intent validation (will be held by default)
    }
}
