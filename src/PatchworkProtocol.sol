// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

    ____        __       __                       __  
   / __ \____ _/ /______/ /_ _      ______  _____/ /__
  / /_/ / __ `/ __/ ___/ __ \ | /| / / __ \/ ___/ //_/
 / ____/ /_/ / /_/ /__/ / / / |/ |/ / /_/ / /  / ,<   
/_/ ___\__,_/\__/\___/_/ /_/|__/|__/\____/_/  /_/|_|  
   / __ \_________  / /_____  _________  / /          
  / /_/ / ___/ __ \/ __/ __ \/ ___/ __ \/ /           
 / ____/ /  / /_/ / /_/ /_/ / /__/ /_/ / /            
/_/   /_/   \____/\__/\____/\___/\____/_/          

*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPatchwork721.sol";
import "./IPatchworkSingleAssignable.sol";
import "./IPatchworkMultiAssignable.sol";
import "./IPatchworkLiteRef.sol";
import "./IPatchworkPatch.sol";
import "./IPatchwork1155Patch.sol";
import "./IPatchworkAccountPatch.sol";
import "./IPatchworkProtocol.sol";
import "./IPatchworkMintable.sol";
import "./IPatchworkScoped.sol";

/** 
@title Patchwork Protocol
@author Runic Labs, Inc
*/
contract PatchworkProtocol is IPatchworkProtocol, Ownable, ReentrancyGuard {

    /// Scopes
    mapping(string => Scope) private _scopes;

    /**
    @notice unique references
    @dev A hash of target + targetTokenId + literef provides uniqueness
    */
    mapping(bytes32 => bool) private _liteRefs;

    /**
    @notice unique patches
    @dev Hash of the patch mapped to a boolean indicating its uniqueness
    */
    mapping(bytes32 => bool) private _uniquePatches;

    /// Balance of the protocol
    uint256 private _protocolBalance;

    /**
    @notice protocol bankers
    @dev Map of addresses authorized to set fees and withdraw funds for the protocol
    @dev Does not allow for scope balance withdrawl
    */
    mapping(address => bool) private _protocolBankers;

    /// Current protocol fee configuration
    ProtocolFeeConfig private _protocolFeeConfig;

    /// scope-based fee overrides
    mapping(string => ProtocolFeeOverride) private _scopeFeeOverrides; 

    mapping(bytes32 => uint8) private _supportedInterfaceCache;

    // TODO maybe not necessary
    uint256 public constant TRANSFER_GAS_LIMIT = 5000;

    /// Constructor
    constructor() Ownable() ReentrancyGuard() {}

    /**
    @dev See {IPatchworkProtocol-claimScope}
    */
    function claimScope(string calldata scopeName) public {
        Scope storage s = _scopes[scopeName];
        if (s.owner != address(0)) {
            revert ScopeExists(scopeName);
        }
        s.owner = msg.sender;
        s.requireWhitelist = true; // better security by default
        emit ScopeClaim(scopeName, msg.sender);
    }

    /**
    @dev See {IPatchworkProtocol-transferScopeOwnership}
    */
    function transferScopeOwnership(string calldata scopeName, address newOwner) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        if (newOwner == address(0)) {
            revert ScopeTransferNotAllowed(address(0));
        }
        s.ownerElect = newOwner;
        emit ScopeTransferElect(scopeName, s.owner, s.ownerElect);
    }

    /**
    @dev See {IPatchworkProtocol-cancelScopeTransfer}
    */
    function cancelScopeTransfer(string calldata scopeName) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        emit ScopeTransferCancel(scopeName, s.owner, s.ownerElect);
        s.ownerElect = address(0);
    }

    /**
    @dev See {IPatchworkProtocol-acceptScopeTransfer}
    */
    function acceptScopeTransfer(string calldata scopeName) public {
        Scope storage s = _mustHaveScope(scopeName);
        if (s.ownerElect == msg.sender) {
            address oldOwner = s.owner;
            s.owner = msg.sender;
            s.ownerElect = address(0);
            emit ScopeTransfer(scopeName, oldOwner, msg.sender);
        } else {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @dev See {IPatchworkProtocol-getScopeOwnerElect}
    */
    function getScopeOwnerElect(string calldata scopeName) public view returns (address ownerElect) {
        return _scopes[scopeName].ownerElect;
    }

    /**
    @dev See {IPatchworkProtocol-getScopeOwner}
    */
    function getScopeOwner(string calldata scopeName) public view returns (address owner) {
        return _scopes[scopeName].owner;
    }

    /**
    @dev See {IPatchworkProtocol-addOperator}
    */
    function addOperator(string calldata scopeName, address op) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.operators[op] = true;
        emit ScopeAddOperator(scopeName, msg.sender, op);
    }

    /**
    @dev See {IPatchworkProtocol-removeOperator}
    */
    function removeOperator(string calldata scopeName, address op) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.operators[op] = false;
        emit ScopeRemoveOperator(scopeName, msg.sender, op);
    }

    /**
    @dev See {IPatchworkProtocol-setScopeRules}
    */
    function setScopeRules(string calldata scopeName, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.allowUserPatch = allowUserPatch;
        s.allowUserAssign = allowUserAssign;
        s.requireWhitelist = requireWhitelist;
        emit ScopeRuleChange(scopeName, msg.sender, allowUserPatch, allowUserAssign, requireWhitelist);
    }

    /**
    @dev See {IPatchworkProtocol-setMintConfiguration}
    */
    function setMintConfiguration(address addr, MintConfig memory config) public {
        IPatchworkMintable mintable = IPatchworkMintable(addr);
        string memory scopeName = mintable.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, addr);
        _mustBeOwnerOrOperator(scope);
        scope.mintConfigurations[addr] = config;
        emit MintConfigure(scopeName, msg.sender, addr, config);
    }

    /**
    @dev See {IPatchworkProtocol-getMintConfiguration}
    */
    function getMintConfiguration(address addr) public view returns (MintConfig memory config) {
        Scope storage scope = _mustHaveScope(IPatchworkMintable(addr).getScopeName());
        return scope.mintConfigurations[addr];
    }

    /**
    @dev See {IPatchworkProtocol-setPatchFee}
    */
    function setPatchFee(address addr, uint256 baseFee) public {
        string memory scopeName = IPatchworkScoped(addr).getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, addr);
        _mustBeOwnerOrOperator(scope);
        scope.patchFees[addr] = baseFee;
    }

    /**
    @dev See {IPatchworkProtocol-getPatchFee}
    */
    function getPatchFee(address addr) public view returns (uint256 baseFee) {
        Scope storage scope = _mustHaveScope(IPatchworkScoped(addr).getScopeName());
        return scope.patchFees[addr];
    }

    /**
    @dev See {IPatchworkProtocol-setAssignFee}
    */
    function setAssignFee(address fragmentAddress, uint256 baseFee) public {
        string memory scopeName = IPatchworkScoped(fragmentAddress).getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, fragmentAddress);
        _mustBeOwnerOrOperator(scope);
        scope.assignFees[fragmentAddress] = baseFee;
    }

    /**
    @dev See {IPatchworkProtocol-getAssignFee}
    */
    function getAssignFee(address fragmentAddress) public view returns (uint256 baseFee) {
        Scope storage scope = _mustHaveScope(IPatchworkScoped(fragmentAddress).getScopeName());
        return scope.assignFees[fragmentAddress];
    }

    /**
    @dev See {IPatchworkProtocol-addBanker}
    */
    function addBanker(string memory scopeName, address addr) public {
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(scope);
        scope.bankers[addr] = true;
        emit ScopeBankerAdd(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-removeBanker}
    */
    function removeBanker(string memory scopeName, address addr) public {
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(scope);
        delete scope.bankers[addr];
        emit ScopeBankerRemove(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-withdraw}
    */
    function withdraw(string memory scopeName, uint256 amount) public nonReentrant {
        Scope storage scope = _mustHaveScope(scopeName);
        if (msg.sender != scope.owner && !scope.bankers[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }
        if (amount > scope.balance) {
            revert InsufficientFunds();
        }
        // modify state before calling to send
        scope.balance -= amount;
        // transfer funds
        // (bool sent,) = msg.sender.call{value: amount, gas: TRANSFER_GAS_LIMIT}(""); // TODO is gas limit good or bad?
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert FailedToSend();
        }
        emit ScopeWithdraw(scopeName, msg.sender, amount);
    }

    /**
    @dev See {IPatchworkProtocol-balanceOf}
    */
    function balanceOf(string memory scopeName) public view returns (uint256 balance) {
        Scope storage scope = _mustHaveScope(scopeName);
        return scope.balance;
    }

    /**
    @dev See {IPatchworkProtocol-mint}
    */
    function mint(address to, address mintable, bytes calldata data) external payable returns (uint256 tokenId) {
        (MintConfig memory config, string memory scopeName, Scope storage scope) = _setupMint(mintable);
        if (msg.value != config.flatFee) {
            revert IncorrectFeeAmount();
        }
        _handleMintFee(scopeName, scope);
        tokenId = IPatchworkMintable(mintable).mint(to, data);
        emit Mint(msg.sender, scopeName, to, mintable, data);
    }
    
    /**
    @dev See {IPatchworkProtocol-mintBatch}
    */
    function mintBatch(address to, address mintable, bytes calldata data, uint256 quantity) external payable returns (uint256[] memory tokenIds) {
        (MintConfig memory config, string memory scopeName, Scope storage scope) = _setupMint(mintable);
        uint256 totalFee = config.flatFee * quantity;
        if (msg.value != totalFee) {
            revert IncorrectFeeAmount();
        }
        _handleMintFee(scopeName, scope);
        tokenIds = IPatchworkMintable(mintable).mintBatch(to, data, quantity);
        emit MintBatch(msg.sender, scopeName, to, mintable, data, quantity);
    }

    /// Common to mints
    function _setupMint(address mintable) internal view returns (MintConfig memory config, string memory scopeName, Scope storage scope) {
        scopeName = IPatchworkMintable(mintable).getScopeName();
        scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, mintable);
        config = scope.mintConfigurations[mintable];
        if (!config.active) {
            revert MintNotActive();
        }
    }

    /// Common to mints
    function _handleMintFee(string memory scopeName, Scope storage scope) internal {
        // Account for 100% of the message value
        if (msg.value != 0) {
            uint256 mintBp;
            ProtocolFeeOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                mintBp = feeOverride.mintBp;
            } else {
                mintBp = _protocolFeeConfig.mintBp;
            }
            uint256 protocolFee = msg.value * mintBp / 10000;
            _protocolBalance += protocolFee;
            scope.balance += msg.value - protocolFee;
        }
    }

    /**
    @dev See {IPatchworkProtocol-setProtocolFeeConfig}
    */
    function setProtocolFeeConfig(ProtocolFeeConfig memory config) public onlyProtoOwnerBanker {
        _protocolFeeConfig = config;
    }

    /**
    @dev See {IPatchworkProtocol-getProtocolFeeConfig}
    */
    function getProtocolFeeConfig() public view returns (ProtocolFeeConfig memory config) {
        return _protocolFeeConfig;
    }

    /**
    @dev See {IPatchworkProtocol-setScopeFeeOverride}
    */
    function setScopeFeeOverride(string memory scopeName, ProtocolFeeOverride memory config) public onlyProtoOwnerBanker {
        if (!config.active) {
            delete _scopeFeeOverrides[scopeName];
        } else {
            _scopeFeeOverrides[scopeName] = config;
        }
    }

    /**
    @dev See {IPatchworkProtocol-getScopeFeeOverride}
    */
    function getScopeFeeOverride(string memory scopeName) public view returns (ProtocolFeeOverride memory config) {
        return _scopeFeeOverrides[scopeName];
    }

    /**
    @dev See {IPatchworkProtocol-addProtocolBanker}
    */
    function addProtocolBanker(address addr) external onlyOwner {
        _protocolBankers[addr] = true;
        emit ProtocolBankerAdd(msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-removeProtocolBanker}
    */
    function removeProtocolBanker(address addr) external onlyOwner {
        delete _protocolBankers[addr];
        emit ProtocolBankerRemove(msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-withdrawFromProtocol}
    */
    function withdrawFromProtocol(uint256 amount) external nonReentrant onlyProtoOwnerBanker {
        if (amount > _protocolBalance) {
            revert InsufficientFunds();
        }
        _protocolBalance -= amount;
        // (bool sent,) = msg.sender.call{value: amount, gas: TRANSFER_GAS_LIMIT}(""); // TODO is gas limit good or bad?
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert FailedToSend();
        }
        emit ProtocolWithdraw(msg.sender, amount);
    }

    function balanceOfProtocol() public view returns (uint256 balance) {
        return _protocolBalance;
    }

    /**
    @dev See {IPatchworkProtocol-addWhitelist}
    */
    function addWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
        s.whitelist[addr] = true;
        emit ScopeWhitelistAdd(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-removeWhitelist}
    */
    function removeWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
        s.whitelist[addr] = false;
        emit ScopeWhitelistRemove(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-patch}
    */
    function patch(address owner, address originalAddress, uint originalTokenId, address patchAddress) external payable returns (uint256 tokenId) {
        IPatchworkPatch patch_ = IPatchworkPatch(patchAddress);
        string memory scopeName = patch_.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, patchAddress));
        if (_uniquePatches[_hash]) {
            revert AlreadyPatched(originalAddress, originalTokenId, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(owner, originalAddress, originalTokenId);
        emit Patch(owner, originalAddress, originalTokenId, patchAddress, tokenId);
        return tokenId;
    }

    /**
    @dev See {IPatchworkProtocol-patchBurned}
    */
    function patchBurned(address originalAddress, uint originalTokenId, address patchAddress) external onlyFrom(patchAddress) {
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, patchAddress));
        delete _uniquePatches[_hash];
    }

    /**
    @dev See {IPatchworkProtocol-patch1155}
    */
    function patch1155(address to, address originalAddress, uint originalTokenId, address originalAccount, address patchAddress) external payable returns (uint256 tokenId) {
        IPatchwork1155Patch patch_ = IPatchwork1155Patch(patchAddress);
        string memory scopeName = patch_.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, originalAccount, patchAddress));
        if (_uniquePatches[_hash]) {
            revert ERC1155AlreadyPatched(originalAddress, originalTokenId, originalAccount, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(to, originalAddress, originalTokenId, originalAccount);
        emit ERC1155Patch(to, originalAddress, originalTokenId, originalAccount, patchAddress, tokenId);
        return tokenId;
    }

    /**
    @dev See {IPatchworkProtocol-patchBurned1155}
    */
    function patchBurned1155(address originalAddress, uint originalTokenId, address originalAccount, address patchAddress) external onlyFrom(patchAddress) {
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, originalAccount, patchAddress));
        delete _uniquePatches[_hash];
    }
    
    /**
    @dev See {IPatchworkProtocol-patchAccount}
    */
    function patchAccount(address owner, address originalAddress, address patchAddress) external payable returns (uint256 tokenId) {
        IPatchworkAccountPatch patch_ = IPatchworkAccountPatch(patchAddress);
        string memory scopeName = patch_.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) { // This allows any user to patch any address
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, patchAddress));
        if (_uniquePatches[_hash]) {
            revert AccountAlreadyPatched(originalAddress, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(owner, originalAddress);
        emit AccountPatch(owner, originalAddress, patchAddress, tokenId);
        return tokenId;
    }

    /**
    @dev See {IPatchworkProtocol-patchBurnedAccount}
    */
    function patchBurnedAccount(address originalAddress, address patchAddress) external onlyFrom(patchAddress) {
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, patchAddress));
        delete _uniquePatches[_hash];
    }

    /// common to patches
    function _handlePatchFee(string memory scopeName, Scope storage scope, address patchAddress) private {
        uint256 patchFee = scope.patchFees[patchAddress];
        if (msg.value != patchFee) {
            revert IncorrectFeeAmount();
        }
        if (msg.value > 0) {
            uint256 patchBp;
            ProtocolFeeOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                patchBp = feeOverride.patchBp;
            } else {
                patchBp = _protocolFeeConfig.patchBp;
            }
            uint256 protocolFee = msg.value * patchBp / 10000;
            _protocolBalance += protocolFee;
            scope.balance += msg.value - protocolFee;
        }
    }

    // common to assigns
    function _handleAssignFee(string memory scopeName, Scope storage scope, address fragmentAddress) private {
        uint256 assignFee = scope.assignFees[fragmentAddress];
        if (msg.value != assignFee) {
            revert IncorrectFeeAmount();
        }
        if (msg.value > 0) {
            uint256 assignBp;
            ProtocolFeeOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                assignBp = feeOverride.assignBp;
            } else {
                assignBp = _protocolFeeConfig.assignBp;
            }
            uint256 protocolFee = msg.value * assignBp / 10000;
            _protocolBalance += protocolFee;
            scope.balance += msg.value - protocolFee;
        }
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public payable mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64 ref = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        IPatchworkLiteRef(target).addReference(targetTokenId, ref);
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public payable mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64 ref = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        IPatchworkLiteRef(target).addReference(targetTokenId, ref, targetMetadataId);
    }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) public payable mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).addReferenceBatch(targetTokenId, refs);
    }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId, uint256 targetMetadataId) public payable mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).addReferenceBatch(targetTokenId, refs, targetMetadataId);
    }

    /**
    @dev Common function to handle the batch assignments.
    */
    function _batchAssignCommon(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) private returns (uint64[] memory refs, address targetOwner) {
        if (fragments.length != tokenIds.length) {
            revert BadInputLengths();
        }
        targetOwner = IERC721(target).ownerOf(targetTokenId);
        refs = new uint64[](fragments.length);
        for (uint i = 0; i < fragments.length; i++) {
            address fragment = fragments[i];
            uint256 fragmentTokenId = tokenIds[i];
            refs[i] = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        }
    }

    /**
    @notice Performs assignment of an IPatchworkAssignable to an IPatchworkLiteRef
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param targetOwner the owner address of the target
    @return uint64 literef of assignable in target
    */
    function _doAssign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, address targetOwner) private mustNotBeFrozen(fragment, fragmentTokenId) returns (uint64) {
        if (fragment == target && fragmentTokenId == targetTokenId) {
            revert SelfAssignmentNotAllowed(fragment, fragmentTokenId);
        }
        IPatchworkAssignable assignable = IPatchworkAssignable(fragment);
        if (_isLocked(fragment, fragmentTokenId)) {
            revert Locked(fragment, fragmentTokenId);
        }
        // Use the target's scope for general permission and check the fragment for detailed permissions
        string memory targetScopeName = IPatchwork721(target).getScopeName();
        Scope storage targetScope = _mustHaveScope(targetScopeName);
        _mustBeWhitelisted(targetScopeName, targetScope, target);
        {
            // Whitelist check, these variables do not need to stay in the function level stack
            string memory fragmentScopeName = assignable.getScopeName();
            Scope storage fragmentScope = _mustHaveScope(fragmentScopeName);
            _mustBeWhitelisted(fragmentScopeName, fragmentScope, fragment);
            _handleAssignFee(fragmentScopeName, fragmentScope, fragment);
        }
        if (targetScope.owner == msg.sender || targetScope.operators[msg.sender]) {
            // all good
        } else if (targetScope.allowUserAssign) {
            // msg.sender must own the target
            if (targetOwner != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
        } else {
            revert NotAuthorized(msg.sender);
        }
        if (!IPatchworkAssignable(fragment).allowAssignment(fragmentTokenId, target, targetTokenId, targetOwner, msg.sender, targetScopeName)) {
            revert NotAuthorized(msg.sender);
        }
        bytes32 targetRef;
        // reduce stack to stay under limit
        address _target = target;
        uint256 _targetTokenId = targetTokenId;
        address _fragment = fragment;
        uint256 _fragmentTokenId = fragmentTokenId;
        (uint64 ref, bool redacted) = IPatchworkLiteRef(_target).getLiteReference(_fragment, _fragmentTokenId);
        // targetRef is a compound key (targetAddr+targetTokenID+fragmentAddr+fragmentTokenID) - blocks duplicate assignments
        targetRef = keccak256(abi.encodePacked(_target, _targetTokenId, ref));
        if (ref == 0) {
            revert FragmentUnregistered(address(_fragment));
        }
        if (redacted) {
            revert FragmentRedacted(address(_fragment));
        }
        if (_liteRefs[targetRef]) {
            revert FragmentAlreadyAssigned(address(_fragment), _fragmentTokenId);
        }
        // call assign on the fragment
        assignable.assign(_fragmentTokenId, _target, _targetTokenId);
        // add to our storage of assignments
        _liteRefs[targetRef] = true;
        emit Assign(targetOwner, _fragment, _fragmentTokenId, _target, _targetTokenId);
        return ref;
    }

    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassign(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassign(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle unassignments.
    */
    function _unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        if (_supportsInterface(fragment, type(IPatchworkMultiAssignable).interfaceId)) {
            if (isDirect) {
                unassignMulti(fragment, fragmentTokenId, target, targetTokenId, targetMetadataId);
            } else {
                unassignMulti(fragment, fragmentTokenId, target, targetTokenId);
            }
        } else if (_supportsInterface(fragment, type(IPatchworkSingleAssignable).interfaceId)) {
            (address _target, uint256 _targetTokenId) = IPatchworkSingleAssignable(fragment).getAssignedTo(fragmentTokenId);
            if (target != _target || _targetTokenId != targetTokenId) {
                revert FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
            }
            if (isDirect) {
                unassignSingle(fragment, fragmentTokenId, targetMetadataId);
            } else {
                unassignSingle(fragment, fragmentTokenId);
            }
        } else {
            revert UnsupportedContract();
        }
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of multi assignables.
    */
    function _unassignMultiCommon(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkMultiAssignable assignable = IPatchworkMultiAssignable(fragment);
        if (!assignable.isAssignedTo(fragmentTokenId, target, targetTokenId)) {
            revert FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
        }
        string memory scopeName = IPatchworkScoped(target).getScopeName();
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignable.unassign(fragmentTokenId, target, targetTokenId);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint fragmentTokenId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint fragmentTokenId, uint256 targetMetadataId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of single assignables.
    */
    function _unassignSingleCommon(address fragment, uint fragmentTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkSingleAssignable assignable = IPatchworkSingleAssignable(fragment);
        (address target, uint256 targetTokenId) = assignable.getAssignedTo(fragmentTokenId);
        if (target == address(0)) {
            revert FragmentNotAssigned(fragment, fragmentTokenId);
        }
        string memory scopeName = IPatchworkScoped(target).getScopeName();
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignable.unassign(fragmentTokenId);
    }

    /**
    @notice Performs unassignment of an IPatchworkAssignable to an IPatchworkLiteRef
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param scopeName the name of the target's scope
    */
    function _doUnassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool direct, uint256 targetMetadataId, string memory scopeName) private {
        Scope storage scope = _mustHaveScope(scopeName);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserAssign) {
            if (IERC721(target).ownerOf(targetTokenId) != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        bytes32 targetRef = keccak256(abi.encodePacked(target, targetTokenId, ref));
        if (!_liteRefs[targetRef]) {
            revert RefNotFound(target, fragment, fragmentTokenId);
        }
        delete _liteRefs[targetRef];
        if (direct) {
            IPatchworkLiteRef(target).removeReference(targetTokenId, ref, targetMetadataId);
        } else {
            IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        }

        emit Unassign(IERC721(fragment).ownerOf(fragmentTokenId), fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @dev See {IPatchworkProtocol-applyTransfer}
    */
    function applyTransfer(address from, address to, uint256 tokenId) public {
        address nft = msg.sender;
        if (_supportsInterface(nft, type(IPatchworkSingleAssignable).interfaceId)) {
            IPatchworkSingleAssignable assignable = IPatchworkSingleAssignable(nft);
            (address addr,) = assignable.getAssignedTo(tokenId);
            if (addr != address(0)) {
                revert TransferBlockedByAssignment(nft, tokenId);
            }
        }
        if (_supportsInterface(nft, type(IPatchworkPatch).interfaceId)) {
            revert TransferNotAllowed(nft, tokenId);
        }
        if (_supportsInterface(nft, type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).locked(tokenId)) {
                revert Locked(nft, tokenId);
            }
        }
        if (_supportsInterface(nft, type(IPatchworkLiteRef).interfaceId)) {
            (address[] memory addresses, uint256[] memory tokenIds) = IPatchworkLiteRef(nft).loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft, tokenId);
                }
            }
        }
    }

    function _applyAssignedTransfer(address nft, address from, address to, uint256 tokenId, address assignedTo_, uint256 assignedToTokenId_) private {
        if (_supportsInterface(nft, type(IPatchworkSingleAssignable).interfaceId)) {
            IPatchworkSingleAssignable singleAssignable = IPatchworkSingleAssignable(nft);
            (address assignedTo, uint256 assignedToTokenId) = singleAssignable.getAssignedTo(tokenId);
            // 2-way Check the assignment to prevent spoofing
            if (assignedTo_ != assignedTo || assignedToTokenId_ != assignedToTokenId) {
                revert DataIntegrityError(assignedTo_, assignedToTokenId_, assignedTo, assignedToTokenId);
            }
            singleAssignable.onAssignedTransfer(from, to, tokenId);
        }

        if (_supportsInterface(nft, type(IPatchworkLiteRef).interfaceId)) {
            address nft_ = nft; // local variable prevents optimizer stack issue in v0.8.18
            (address[] memory addresses, uint256[] memory tokenIds) = IPatchworkLiteRef(nft).loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft_, tokenId);
                }
            }
        }
    }

    /**
    @dev See {IPatchworkProtocol-updateOwnershipTree}
    */ 
    function updateOwnershipTree(address addr, uint256 tokenId) public {
        if (_supportsInterface(addr, type(IPatchworkLiteRef).interfaceId)) {
            (address[] memory addresses, uint256[] memory tokenIds) = IPatchworkLiteRef(addr).loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    updateOwnershipTree(addresses[i], tokenIds[i]);
                }
            }
        }
        if (_supportsInterface(addr, type(IPatchworkSingleAssignable).interfaceId)) {
            IPatchworkSingleAssignable(addr).updateOwnership(tokenId);
        } else if (_supportsInterface(addr, type(IPatchworkPatch).interfaceId)) {
            IPatchworkPatch(addr).updateOwnership(tokenId);
        }
    }

    /**
    @notice Requires that scopeName is present
    @dev will revert with ScopeDoesNotExist if not present
    @return scope the scope
    */
    function _mustHaveScope(string memory scopeName) private view returns (Scope storage scope) {
        scope = _scopes[scopeName];
        if (scope.owner == address(0)) {
            revert ScopeDoesNotExist(scopeName);
        }
    }

    /**
    @notice Requires that addr is whitelisted if whitelisting is enabled
    @dev will revert with NotWhitelisted if whitelisting is enabled and address is not whitelisted
    @param scopeName the name of the scope
    @param scope the scope
    @param addr the address to check
    */
    function _mustBeWhitelisted(string memory scopeName, Scope storage scope, address addr) private view {
        if (scope.requireWhitelist && !scope.whitelist[addr]) {
            revert NotWhitelisted(scopeName, addr);
        }
    }

    /**
    @notice Requires that msg.sender is owner of scope
    @dev will revert with NotAuthorized if msg.sender is not owner
    @param scope the scope
    */
    function _mustBeOwner(Scope storage scope) private view {
        if (msg.sender != scope.owner) {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @notice Requires that msg.sender is owner or operator of scope
    @dev will revert with NotAuthorized if msg.sender is not owner or operator
    @param scope the scope
    */
    function _mustBeOwnerOrOperator(Scope storage scope) private view {
        if (msg.sender != scope.owner && !scope.operators[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @notice Requires that nft is not frozen
    @dev will revert with Frozen if nft is frozen
    @param nft the address of nft
    @param tokenId the tokenId of nft
    */
    modifier mustNotBeFrozen(address nft, uint256 tokenId) {
        if (_isFrozen(nft, tokenId)) {
            revert Frozen(nft, tokenId);
        }
        _;
    }

    /**
    @notice Determines if nft is frozen using ownership hierarchy
    @param nft the address of nft
    @param tokenId the tokenId of nft
    @return frozen if the nft or an owner up the tree is frozen
    */
    function _isFrozen(address nft, uint256 tokenId) private returns (bool frozen) {
        if (_supportsInterface(nft, type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).frozen(tokenId)) {
                return true;
            }
            if (_supportsInterface(nft, type(IPatchworkSingleAssignable).interfaceId)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkSingleAssignable(nft).getAssignedTo(tokenId);
                if (assignedAddr != address(0)) {
                    return _isFrozen(assignedAddr, assignedTokenId);
                }
            }
        }
        return false;
    }

    /**
    @notice Determines if nft is locked
    @param nft the address of nft
    @param tokenId the tokenId of nft
    @return locked if the nft is locked
    */
    function _isLocked(address nft, uint256 tokenId) private returns (bool locked) {
        if (_supportsInterface(nft, type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).locked(tokenId)) {
                return true;
            }
        }
        return false;
    }

    function _supportsInterface(address addr, bytes4 sig) private returns (bool ret) {
        bytes32 _hash = keccak256(abi.encodePacked(addr, sig));
        uint8 support = _supportedInterfaceCache[_hash];
        if (support == 1) {
            return true;
        } else if (support == 2) {
            return false;
        } else {
            ret = IERC165(addr).supportsInterface(sig);
            if (ret) {
                _supportedInterfaceCache[_hash] = 1;
            } else {
                _supportedInterfaceCache[_hash] = 2;
            }
            return ret;
        }
    }

    function clearSupportedInterface(bytes4 sig) external {
       delete _supportedInterfaceCache[keccak256(abi.encodePacked(msg.sender, sig))];
    }

    modifier onlyProtoOwnerBanker() {
        if (msg.sender != owner() && _protocolBankers[msg.sender] == false) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    modifier onlyFrom(address addr) {
        if (msg.sender != addr) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }
}