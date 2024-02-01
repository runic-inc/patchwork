// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
import "./PatchworkProtocolCommon.sol";
import "./interfaces/IPatchwork721.sol";
import "./interfaces/IPatchworkSingleAssignable.sol";
import "./interfaces/IPatchworkMultiAssignable.sol";
import "./interfaces/IPatchworkLiteRef.sol";
import "./interfaces/IPatchworkPatch.sol";
import "./interfaces/IPatchwork1155Patch.sol";
import "./interfaces/IPatchworkAccountPatch.sol";
import "./interfaces/IPatchworkProtocol.sol";
import "./interfaces/IPatchworkMintable.sol";
import "./interfaces/IPatchworkScoped.sol";

/** 
@title Patchwork Protocol
@author Runic Labs, Inc
*/
contract PatchworkProtocol is IPatchworkProtocol, PatchworkProtocolCommon {
    
    /// How much time must elapse before a fee change can be committed (1209600 = 2 weeks)
    uint256 public constant FEE_CHANGE_TIMELOCK = 1209600; 

    /// How much time must elapse before a contract upgrade can be committed (1209600 = 2 weeks)
    uint256 public constant CONTRACT_UPGRADE_TIMELOCK = 1209600; 

    /// The denominator for fee basis points
    uint256 private constant _FEE_BASIS_DENOM = 10000;

    /// The maximum basis points patchwork can ever be configured to
    uint256 private constant _PROTOCOL_FEE_CEILING = 3000;

    /// Constructor
    /// @param owner_ The address of the initial owner
    constructor(address owner_, address assignerDelegate_) PatchworkProtocolCommon(owner_) {
        _assignerDelegate = assignerDelegate_;
    }

    /**
    @dev See {IPatchworkProtocol-claimScope}
    */
    function claimScope(string calldata scopeName) public {
        if (bytes(scopeName).length == 0) {
            revert NotAuthorized(msg.sender);
        }
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
        if (!IERC165(addr).supportsInterface(type(IPatchworkMintable).interfaceId)) {
            revert UnsupportedContract();
        }
        string memory scopeName = _getScopeName(addr);
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
        if (!IERC165(addr).supportsInterface(type(IPatchworkMintable).interfaceId)) {
            revert UnsupportedContract();
        }
        Scope storage scope = _mustHaveScope(_getScopeNameViewOnly(addr));
        return scope.mintConfigurations[addr];
    }

    /**
    @dev See {IPatchworkProtocol-setPatchFee}
    */
    function setPatchFee(address addr, uint256 baseFee) public {
        if (!IERC165(addr).supportsInterface(type(IPatchworkScoped).interfaceId)) {
            revert UnsupportedContract();
        }
        string memory scopeName = _getScopeName(addr);
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, addr);
        _mustBeOwnerOrOperator(scope);
        scope.patchFees[addr] = baseFee;
        emit PatchFeeChange(scopeName, addr, baseFee);
    }

    /**
    @dev See {IPatchworkProtocol-getPatchFee}
    */
    function getPatchFee(address addr) public view returns (uint256 baseFee) {
        if (!IERC165(addr).supportsInterface(type(IPatchworkScoped).interfaceId)) {
            revert UnsupportedContract();
        }
        Scope storage scope = _mustHaveScope(_getScopeNameViewOnly(addr));
        return scope.patchFees[addr];
    }

    /**
    @dev See {IPatchworkProtocol-setAssignFee}
    */
    function setAssignFee(address fragmentAddress, uint256 baseFee) public {
        if (!IERC165(fragmentAddress).supportsInterface(type(IPatchworkScoped).interfaceId)) {
            revert UnsupportedContract();
        }
        string memory scopeName = _getScopeName(fragmentAddress);
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, fragmentAddress);
        _mustBeOwnerOrOperator(scope);
        scope.assignFees[fragmentAddress] = baseFee;
        emit AssignFeeChange(scopeName, fragmentAddress, baseFee);
    }

    /**
    @dev See {IPatchworkProtocol-getAssignFee}
    */
    function getAssignFee(address fragmentAddress) public view returns (uint256 baseFee) {
        if (!IERC165(fragmentAddress).supportsInterface(type(IPatchworkScoped).interfaceId)) {
            revert UnsupportedContract();
        }
        Scope storage scope = _mustHaveScope(_getScopeNameViewOnly(fragmentAddress));
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
        (uint256 scopeFee, uint256 protocolFee) = _handleMintFee(scopeName, scope);
        tokenId = IPatchworkMintable(mintable).mint(to, data);
        emit Mint(msg.sender, scopeName, to, mintable, data, scopeFee, protocolFee);
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
        (uint256 scopeFee, uint256 protocolFee) = _handleMintFee(scopeName, scope);
        tokenIds = IPatchworkMintable(mintable).mintBatch(to, data, quantity);
        emit MintBatch(msg.sender, scopeName, to, mintable, data, quantity, scopeFee, protocolFee);
    }

    /// Common to mints
    function _setupMint(address mintable) internal view returns (MintConfig memory config, string memory scopeName, Scope storage scope) {
        if (!IERC165(mintable).supportsInterface(type(IPatchworkMintable).interfaceId)) {
            revert UnsupportedContract();
        }
        scopeName = _getScopeNameViewOnly(mintable);
        scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, mintable);
        config = scope.mintConfigurations[mintable];
        if (!config.active) {
            revert MintNotActive();
        }
    }

    /// Common to mints
    function _handleMintFee(string memory scopeName, Scope storage scope) internal returns (uint256 scopeFee, uint256 protocolFee) {
        // Account for 100% of the message value
        if (msg.value != 0) {
            uint256 mintBp;
            FeeConfigOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                mintBp = feeOverride.mintBp;
            } else {
                mintBp = _protocolFeeConfig.mintBp;
            }
            protocolFee = msg.value * mintBp / _FEE_BASIS_DENOM;
            scopeFee = msg.value - protocolFee;
            _protocolBalance += protocolFee;
            scope.balance += scopeFee;
        }
    }

    /**
    @dev See {IPatchworkProtocol-proposeProtocolFeeConfig}
    */
    function proposeProtocolFeeConfig(FeeConfig memory config) public onlyProtoOwnerBanker {
        if (config.assignBp > _PROTOCOL_FEE_CEILING || config.mintBp > _PROTOCOL_FEE_CEILING || config.patchBp > _PROTOCOL_FEE_CEILING) {
            revert InvalidFeeValue();
        }
        _proposedFeeConfigs[""] = ProposedFeeConfig(config, block.timestamp, true);
        emit ProtocolFeeConfigPropose(config);
    }

    /**
    @dev See {IPatchworkProtocol-commitProtocolFeeConfig}
    */
    function commitProtocolFeeConfig() public onlyProtoOwnerBanker {
        (FeeConfig memory config, /* bool active */) = _preCommitFeeChange("");
        _protocolFeeConfig = config;
        emit ProtocolFeeConfigCommit(_protocolFeeConfig);
    }

    /**
    @dev See {IPatchworkProtocol-getProtocolFeeConfig}
    */
    function getProtocolFeeConfig() public view returns (FeeConfig memory config) {
        return _protocolFeeConfig;
    }

    /**
    @dev See {IPatchworkProtocol-proposeScopeFeeOverride}
    */
    function proposeScopeFeeOverride(string memory scopeName, FeeConfigOverride memory config) public onlyProtoOwnerBanker {
        if (config.assignBp > _PROTOCOL_FEE_CEILING || config.mintBp > _PROTOCOL_FEE_CEILING || config.patchBp > _PROTOCOL_FEE_CEILING) {
            revert InvalidFeeValue();
        }
        _proposedFeeConfigs[scopeName] = ProposedFeeConfig(
            FeeConfig(config.mintBp, config.patchBp, config.assignBp), block.timestamp, config.active);
        emit ScopeFeeOverridePropose(scopeName, config);
    }

    /**
    @dev See {IPatchworkProtocol-commitScopeFeeOverride}
    */
    function commitScopeFeeOverride(string memory scopeName) public onlyProtoOwnerBanker {
        (FeeConfig memory config, bool active) = _preCommitFeeChange(scopeName);
        FeeConfigOverride memory feeOverride = FeeConfigOverride(config.mintBp, config.patchBp, config.assignBp, active);
        if (!active) {
            delete _scopeFeeOverrides[scopeName];
        } else {
            _scopeFeeOverrides[scopeName] = feeOverride;
        }
        emit ScopeFeeOverrideCommit(scopeName, feeOverride);
    }

    /**
    @dev commits a fee change if a proposal exists and timelock is satisfied
    @param scopeName "" for protocol or the scope name
    @return config The proposed config
    @return active The proposed active state (only applies to fee overrides)
    */
    function _preCommitFeeChange(string memory scopeName) private returns (FeeConfig memory config, bool active) {
        ProposedFeeConfig storage proposal = _proposedFeeConfigs[scopeName];
        if (proposal.timestamp == 0) {
            revert NoProposedFeeSet();
        }
        if (block.timestamp < proposal.timestamp + FEE_CHANGE_TIMELOCK) {
            revert TimelockNotElapsed();
        }
        config = proposal.config;
        active = proposal.active;
        delete _proposedFeeConfigs[scopeName];
    }

    /**
    @dev See {IPatchworkProtocol-getScopeFeeOverride}
    */
    function getScopeFeeOverride(string memory scopeName) public view returns (FeeConfigOverride memory config) {
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
        if (!IERC165(patchAddress).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            revert UnsupportedContract();
        }
        IPatchworkPatch patch_ = IPatchworkPatch(patchAddress);
        string memory scopeName = _getScopeName(patchAddress);
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (uint256 scopeFee, uint256 protocolFee) = _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, patchAddress));
        if (_uniquePatches[_hash]) {
            revert AlreadyPatched(originalAddress, originalTokenId, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(owner, IPatchworkPatch.PatchTarget(originalAddress, originalTokenId));
        emit Patch(owner, originalAddress, originalTokenId, patchAddress, tokenId, scopeFee, protocolFee);
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
        if (!IERC165(patchAddress).supportsInterface(type(IPatchwork1155Patch).interfaceId)) {
            revert UnsupportedContract();
        }
        IPatchwork1155Patch patch_ = IPatchwork1155Patch(patchAddress);
        string memory scopeName = _getScopeName(patchAddress);
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (uint256 scopeFee, uint256 protocolFee) = _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, originalTokenId, originalAccount, patchAddress));
        if (_uniquePatches[_hash]) {
            revert ERC1155AlreadyPatched(originalAddress, originalTokenId, originalAccount, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(to, IPatchwork1155Patch.PatchTarget(originalAddress, originalTokenId, originalAccount));
        emit ERC1155Patch(to, originalAddress, originalTokenId, originalAccount, patchAddress, tokenId, scopeFee, protocolFee);
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
        if (!IERC165(patchAddress).supportsInterface(type(IPatchworkAccountPatch).interfaceId)) {
            revert UnsupportedContract();
        }
        IPatchworkAccountPatch patch_ = IPatchworkAccountPatch(patchAddress);
        string memory scopeName = _getScopeName(patchAddress);
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) { // This allows any user to patch any address
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (uint256 scopeFee, uint256 protocolFee) = _handlePatchFee(scopeName, scope, patchAddress);
        // limit this to one unique patch (originalAddress+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, patchAddress));
        if (_uniquePatches[_hash]) {
            revert AccountAlreadyPatched(originalAddress, patchAddress);
        }
        _uniquePatches[_hash] = true;
        tokenId = patch_.mintPatch(owner, originalAddress);
        emit AccountPatch(owner, originalAddress, patchAddress, tokenId, scopeFee, protocolFee);
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
    function _handlePatchFee(string memory scopeName, Scope storage scope, address patchAddress) private returns (uint256 scopeFee, uint256 protocolFee) {
        uint256 patchFee = scope.patchFees[patchAddress];
        if (msg.value != patchFee) {
            revert IncorrectFeeAmount();
        }
        if (msg.value > 0) {
            uint256 patchBp;
            FeeConfigOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                patchBp = feeOverride.patchBp;
            } else {
                patchBp = _protocolFeeConfig.patchBp;
            }
            protocolFee = msg.value * patchBp / _FEE_BASIS_DENOM;
            scopeFee = msg.value - protocolFee;
            _protocolBalance += protocolFee;
            scope.balance += scopeFee;
        }
    }

    function _delegatecall(address delegate, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = delegate.delegatecall(data);
        if (!success) {
            if (returndata.length == 0) revert();
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
        return returndata;
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public payable {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("assign(address,uint256,address,uint256)", fragment, fragmentTokenId, target, targetTokenId));
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public payable {
         _delegatecall(_assignerDelegate, abi.encodeWithSignature("assign(address,uint256,address,uint256,uint256)", fragment, fragmentTokenId, target, targetTokenId, targetMetadataId));
   }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId) public payable {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("assignBatch(address[],uint256[],address,uint256)", fragments, tokenIds, target, targetTokenId));
    }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId, uint256 targetMetadataId) public payable {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("assignBatch(address[],uint256[],address,uint256,uint256)", fragments, tokenIds, target, targetTokenId, targetMetadataId));
    }
    
    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassign(address,uint256,address,uint256)", fragment, fragmentTokenId, target, targetTokenId));
    }

    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassign(address,uint256,address,uint256,uint256)", fragment, fragmentTokenId, target, targetTokenId, targetMetadataId));
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassignMulti(address,uint256,address,uint256)", fragment, fragmentTokenId, target, targetTokenId));
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassignMulti(address,uint256,address,uint256,uint256)", fragment, fragmentTokenId, target, targetTokenId, targetMetadataId));
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassignSingle(address,uint256)", fragment, fragmentTokenId));
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId, uint256 targetMetadataId) public {
        _delegatecall(_assignerDelegate, abi.encodeWithSignature("unassignSingle(address,uint256,uint256)", fragment, fragmentTokenId, targetMetadataId));
    }

    /**
    @dev See {IPatchworkProtocol-applyTransfer}
    */
    function applyTransfer(address from, address to, uint256 tokenId) public {
        address nft = msg.sender;
        if (IERC165(nft).supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
            IPatchworkSingleAssignable assignable = IPatchworkSingleAssignable(nft);
            (address addr,) = assignable.getAssignedTo(tokenId);
            if (addr != address(0)) {
                revert TransferBlockedByAssignment(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            revert TransferNotAllowed(nft, tokenId);
        }
        if (IERC165(nft).supportsInterface(type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).locked(tokenId)) {
                revert Locked(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
            (address[] memory addresses, uint256[] memory tokenIds) = IPatchworkLiteRef(nft).loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft, tokenId);
                }
            }
        }
    }

    function _applyAssignedTransfer(address nft, address from, address to, uint256 tokenId, address assignedTo_, uint256 assignedToTokenId_) private {
        if (!IERC165(nft).supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
            revert NotPatchworkAssignable(nft);
        }
        (address assignedTo, uint256 assignedToTokenId) = IPatchworkSingleAssignable(nft).getAssignedTo(tokenId);
        // 2-way Check the assignment to prevent spoofing
        if (assignedTo_ != assignedTo || assignedToTokenId_ != assignedToTokenId) {
            revert DataIntegrityError(assignedTo_, assignedToTokenId_, assignedTo, assignedToTokenId);
        }
        IPatchworkSingleAssignable(nft).onAssignedTransfer(from, to, tokenId);
        if (IERC165(nft).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
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
        if (IERC165(addr).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
            (address[] memory addresses, uint256[] memory tokenIds) = IPatchworkLiteRef(addr).loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    updateOwnershipTree(addresses[i], tokenIds[i]);
                }
            }
        }
        if (IERC165(addr).supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
            IPatchworkSingleAssignable(addr).updateOwnership(tokenId);
        } else if (IERC165(addr).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            IPatchworkPatch(addr).updateOwnership(tokenId);
        }
    }

    /**
    @dev See {IPatchworkProtocol-proposeAssignerDelegate}
    */
    function proposeAssignerDelegate(address addr) public onlyOwner {
        if (addr == address(0)) {
            // effectively a cancel
            _proposedAssignerDelegate = ProposedAssignerDelegate(0, address(0));
        } else {
            _proposedAssignerDelegate = ProposedAssignerDelegate(block.timestamp, addr);
        }
        emit AssignerDelegatePropose(addr);
    }

    /**
    @dev See {IPatchworkProtocol-commitAssignerDelegate}
    */
    function commitAssignerDelegate() public onlyOwner {
        if (_proposedAssignerDelegate.timestamp == 0) {
            revert NoDelegateProposed();
        }
        if (block.timestamp < _proposedAssignerDelegate.timestamp + CONTRACT_UPGRADE_TIMELOCK) {
            revert TimelockNotElapsed();
        }
        _assignerDelegate = _proposedAssignerDelegate.addr;
        _proposedAssignerDelegate = ProposedAssignerDelegate(0, address(0));
        emit AssignerDelegateCommit(_assignerDelegate);
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
    @notice Memoized view-only wrapper for IPatchworkScoped.getScopeName()
    @dev required to get optimized result from view-only functions, does not memoize result if not already memoized
    @param addr Address to check
    @return scopeName return value of IPatchworkScoped(addr).getScopeName()
    */
    function _getScopeNameViewOnly(address addr) private view returns (string memory scopeName) {
        scopeName = _scopeNameCache[addr];
        if (bytes(scopeName).length == 0) {
            scopeName = IPatchworkScoped(addr).getScopeName();
        }
    }

    /// Only protocol owner or protocol banker
    modifier onlyProtoOwnerBanker() {
        if (msg.sender != owner() && _protocolBankers[msg.sender] == false) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    /// Only msg.sender from addr
    modifier onlyFrom(address addr) {
        if (msg.sender != addr) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }
}