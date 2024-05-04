// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
@title Patchwork Dynamic Reference Library
@dev using this will save code space in your 721 contract at the expense of CALLs to this library (roughly 700 gas)
 */
library PatchworkDynamicRefs {

    error AlreadyLoaded();
    error NotFound();
    error StorageIntegrityError();

    /**
    @notice A struct to hold dynamic references
    */
    struct DynamicLiteRefs {
        uint256[] slots; // 4 per
        mapping(uint64 => uint256) idx;
    }

    /**
    @dev See {IPatchworkLiteRef-addReference}
    */
    function addReference(uint64 liteRef, DynamicLiteRefs storage store) public {
        // to append: find last slot, if it's not full, add, otherwise start a new slot.
        uint256 slotsLen = store.slots.length;
        if (slotsLen == 0) {
            store.slots.push(uint256(liteRef));
            store.idx[liteRef] = 0;
        } else {
            uint256 slot = store.slots[slotsLen-1];
            if (slot >= (1 << 192)) {
                // new slot (pos 1)
                store.slots.push(uint256(liteRef));
                store.idx[liteRef] = slotsLen;
            } else {
                store.idx[liteRef] = slotsLen-1;
                // Reverse search for the next empty subslot
                for (uint256 i = 3; i > 0; i--) {
                    if (slot >= (1 << ((i-1) * 64))) {
                        // pos 4 through 2
                        store.slots[slotsLen-1] = slot | uint256(liteRef) << (i*64);
                        break;
                    }
                }
            }
        }
    }

    /**
    @dev See {IPatchworkLiteRef-addReferenceBatch}
    */
    function addReferenceBatch(uint64[] calldata liteRefs, DynamicLiteRefs storage store) public {
        uint256 slotsLen = store.slots.length;
        if (slotsLen > 0) {
            revert AlreadyLoaded();
        }
        uint256 fullBatchCount = liteRefs.length / 4;
        uint256 remainder = liteRefs.length % 4;
        for (uint256 batch = 0; batch < fullBatchCount; batch++) {
            uint256 refIdx = batch * 4;
            uint256 slot = uint256(liteRefs[refIdx]) | (uint256(liteRefs[refIdx+1]) << 64) | (uint256(liteRefs[refIdx+2]) << 128) | (uint256(liteRefs[refIdx+3]) << 192);
            store.slots.push(slot);
            for (uint256 i = 0; i < 4; i++) {
                store.idx[liteRefs[refIdx + i]] = batch;
            }
        }
        uint256 rSlot;
        for (uint256 i = 0; i < remainder; i++) {
            uint256 idx = (fullBatchCount * 4) + i;
            rSlot = rSlot | (uint256(liteRefs[idx]) << (i * 64));
            store.idx[liteRefs[idx]] = fullBatchCount;
        }
        store.slots.push(rSlot);
    }

    /**
    @dev See {IPatchworkLiteRef-removeReference}
    */
    function removeReference(uint64 liteRef, DynamicLiteRefs storage store) public {
        uint256 slotsLen = store.slots.length;
        if (slotsLen == 0) {
            revert NotFound();
        }

        uint256 count = getDynamicReferenceCount(store);
        if (count == 1) {
            if (store.slots[0] == liteRef) {
                store.slots.pop();
                delete store.idx[liteRef];
            } else {
                revert NotFound();
            }
        } else {
            // remember and remove the last ref
            uint256 lastIdx = slotsLen-1;
            uint256 slot = store.slots[lastIdx];
            uint64 lastRef;

            for (uint256 i = 3; i > 0; i--) {
                uint256 shift = i * 64;
                if (slot >= (1 << shift)) {
                    // pos 4 through 2
                    lastRef = uint64(slot >> shift);
                    uint256 mask = ~uint256(0) >> (256 - shift);
                    store.slots[lastIdx] = slot & mask;
                    break;
                }
            }
            if (lastRef == 0) {
                // pos 1
                lastRef = uint64(slot);
                store.slots.pop();
            }

            if (lastRef == liteRef) {
                // it was the last ref. No need to replace anything. It's already cleared so just clear the index
                delete store.idx[liteRef];
            } else {
                // Find the ref and replace it with lastRef then update indexes
                uint256 refSlotIdx = store.idx[liteRef];
                slot = store.slots[refSlotIdx];
                uint256 oldSlot = slot;
                for (uint256 i = 4; i > 0; i--) {
                    uint256 shift = (i-1) * 64;
                    if (uint64(slot >> shift) == liteRef) {
                        uint256 mask = ~(uint256(0xFFFFFFFFFFFFFFFF) << shift);
                        slot = (slot & mask) | (uint256(lastRef) << shift);
                        break;
                    }
                }
                if (oldSlot == slot) {
                    revert StorageIntegrityError();
                }
                store.slots[refSlotIdx] = slot;
                store.idx[lastRef] = refSlotIdx;
                delete store.idx[liteRef];
            }
        }
    }

    /**
    @notice loads a dynamic ref from storage
    @param idx The index of the ref to load
    @param store The storage to load from
    @return ref The ref at the given index
    */
    function loadRef(uint256 idx, DynamicLiteRefs storage store) public view returns (uint64 ref) {
        uint256[] storage slots = store.slots;
        uint slotNumber = idx / 4; // integer division will get the correct slot number
        uint shift = (idx % 4) * 64; // the remainder will give the correct shift
        ref = uint64(slots[slotNumber] >> shift);
    }

    /**
    @dev See {IPatchworkLiteRef-getDynamicReferenceCount}
    */
    function getDynamicReferenceCount(DynamicLiteRefs storage store) public view returns (uint256 count) {
        uint256 slotsLen = store.slots.length;
        if (slotsLen == 0) {
            return 0;
        } else {
            uint256 slot = store.slots[slotsLen-1];
            for (uint256 i = 4; i > 1; i--) {
                uint256 shift = (i-1) * 64;
                if (slot >= (1 << shift)) {
                    return (slotsLen-1) * 4 + i;
                }
            }
            return (slotsLen-1) * 4 + 1;
        }
    }

    /**
    @notice loads a page of dynamic refs from storage
    @param offset The offset to start at
    @param count The number of refs to load
    @param store The storage to load from
    @return refs The refs at the given offset
    */
    function loadRefPage(uint256 offset, uint256 count, DynamicLiteRefs storage store) public view returns (uint64[] memory refs) {
        uint256 refCount = getDynamicReferenceCount(store);
        if (offset >= refCount) {
            return (new uint64[](0));
        }
        uint256 realCount = refCount - offset;
        if (realCount > count) {
            realCount = count;
        }
        refs = new uint64[](realCount);
        uint256[] storage slots = store.slots;
        // start at offset
        for (uint256 i = 0; i < realCount; i++) {
            uint256 idx = offset + i;
            uint slotNumber = idx / 4; // integer division will get the correct slot number
            uint shift = (idx % 4) * 64; // the remainder will give the correct shift
            uint64 ref = uint64(slots[slotNumber] >> shift);
            refs[i] = ref;
        }
    }
}