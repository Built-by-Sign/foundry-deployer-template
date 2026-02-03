// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ExampleContract} from "../src/ExampleContract.sol";
import {Initializable} from "solady/utils/Initializable.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract ExampleContractTest is Test {
    ExampleContract public example;
    address public owner = address(0x1);
    address public user = address(0x2);

    event ValueUpdated(uint256 oldValue, uint256 newValue);

    function setUp() public {
        example = new ExampleContract();

        vm.prank(owner);
        example.initialize(100, owner);
    }

    function test_Initialize() public view {
        assertEq(example.value(), 100);
        assertEq(example.owner(), owner);
    }

    function test_Version() public view {
        assertEq(example.version(), example.VERSION());
    }

    function test_SetValue() public {
        vm.prank(owner);
        example.setValue(200);

        assertEq(example.value(), 200);
    }

    function test_RevertWhen_NonOwnerSetsValue() public {
        vm.prank(user);
        vm.expectRevert(Ownable.Unauthorized.selector);
        example.setValue(300);
    }

    function test_EmitValueUpdated() public {
        vm.expectEmit(true, true, true, true);
        emit ValueUpdated(100, 200);

        vm.prank(owner);
        example.setValue(200);
    }

    function test_RevertWhen_ReinitializeAttempted() public {
        vm.prank(user);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        example.initialize(999, user);
    }

    function testFuzz_SetValue(uint256 newValue) public {
        vm.prank(owner);
        example.setValue(newValue);
        assertEq(example.value(), newValue);
    }

    // ============ Ownership Tests ============

    function test_TransferOwnership() public {
        address newOwner = address(0x3);

        vm.prank(owner);
        example.transferOwnership(newOwner);

        assertEq(example.owner(), newOwner);
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        address newOwner = address(0x3);

        vm.prank(user);
        vm.expectRevert(Ownable.Unauthorized.selector);
        example.transferOwnership(newOwner);
    }

    function test_RenounceOwnership() public {
        vm.prank(owner);
        example.renounceOwnership();

        assertEq(example.owner(), address(0));
    }

    function test_RevertWhen_NonOwnerRenouncesOwnership() public {
        vm.prank(user);
        vm.expectRevert(Ownable.Unauthorized.selector);
        example.renounceOwnership();
    }

    function test_OwnershipHandoverFlow() public {
        address newOwner = address(0x3);

        // New owner requests handover
        vm.prank(newOwner);
        example.requestOwnershipHandover();

        // Current owner completes handover
        vm.prank(owner);
        example.completeOwnershipHandover(newOwner);

        assertEq(example.owner(), newOwner);
    }

    function test_RevertWhen_CompletingHandoverWithoutRequest() public {
        address newOwner = address(0x3);

        vm.prank(owner);
        vm.expectRevert(Ownable.NoHandoverRequest.selector);
        example.completeOwnershipHandover(newOwner);
    }

    function test_CancelOwnershipHandover() public {
        address newOwner = address(0x3);

        // Request handover
        vm.prank(newOwner);
        example.requestOwnershipHandover();

        // Cancel handover
        vm.prank(newOwner);
        example.cancelOwnershipHandover();

        // Attempt to complete should fail
        vm.prank(owner);
        vm.expectRevert(Ownable.NoHandoverRequest.selector);
        example.completeOwnershipHandover(newOwner);
    }

    function test_RevertWhen_NonOwnerCompletesHandover() public {
        address newOwner = address(0x3);

        vm.prank(newOwner);
        example.requestOwnershipHandover();

        vm.prank(user);
        vm.expectRevert(Ownable.Unauthorized.selector);
        example.completeOwnershipHandover(newOwner);
    }

    // ============ Edge Case Tests ============

    function test_InitializeWithZeroValue() public {
        ExampleContract newContract = new ExampleContract();

        vm.prank(owner);
        newContract.initialize(0, owner);

        assertEq(newContract.value(), 0);
        assertEq(newContract.owner(), owner);
    }

    function test_SetValueToMaxUint256() public {
        vm.prank(owner);
        example.setValue(type(uint256).max);

        assertEq(example.value(), type(uint256).max);
    }
}
