// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    // Basic Tests
    function testBobBalance() public {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testInitialSupply() public {
        assertEq(INITIAL_SUPPLY, ourToken.totalSupply());
    }

    function testTokenNameAndSymbol() public {
        assertEq("OurToken", ourToken.name());
        assertEq("OT", ourToken.symbol());
    }

    // Transfer Tests
    function testTransfer() public {
        uint256 transferAmount = 10 ether;

        // Test transfer from bob to alice
        vm.prank(bob);
        bool success = ourToken.transfer(alice, transferAmount);

        assertTrue(success);
        assertEq(transferAmount, ourToken.balanceOf(alice));
        assertEq(STARTING_BALANCE - transferAmount, ourToken.balanceOf(bob));
    }

    function testTransferEmitsEvent() public {
        uint256 transferAmount = 10 ether;

        // Test that transfer emits the correct event
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, transferAmount);
        ourToken.transfer(alice, transferAmount);
    }

    function testFailTransferInsufficientBalance() public {
        uint256 invalidAmount = STARTING_BALANCE + 1 ether;

        // This should fail because bob doesn't have enough tokens
        vm.prank(bob);
        ourToken.transfer(alice, invalidAmount);
    }

    function testFailTransferToZeroAddress() public {
        vm.prank(bob);
        ourToken.transfer(address(0), 10 ether);
    }

    // Allowance Tests
    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testApproveEmitsEvent() public {
        uint256 amount = 1000;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, amount);
        ourToken.approve(alice, amount);
    }

    // Multiple Transfers and Allowances
    function testMultipleTransfers() public {
        uint256 transferAmount = 10 ether;

        // Bob transfers to Alice
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        // Alice transfers to Charlie
        vm.prank(alice);
        ourToken.transfer(charlie, transferAmount / 2);

        assertEq(transferAmount / 2, ourToken.balanceOf(alice));
        assertEq(transferAmount / 2, ourToken.balanceOf(charlie));
        assertEq(STARTING_BALANCE - transferAmount, ourToken.balanceOf(bob));
    }

    function testMultipleAllowances() public {
        // Bob approves both Alice and Charlie
        vm.startPrank(bob);
        ourToken.approve(alice, 1000);
        ourToken.approve(charlie, 500);
        vm.stopPrank();

        assertEq(1000, ourToken.allowance(bob, alice));
        assertEq(500, ourToken.allowance(bob, charlie));

        // Both spend some of their allowance
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 300);

        vm.prank(charlie);
        ourToken.transferFrom(bob, charlie, 200);

        assertEq(700, ourToken.allowance(bob, alice));
        assertEq(300, ourToken.allowance(bob, charlie));

        assertEq(300, ourToken.balanceOf(alice));
        assertEq(200, ourToken.balanceOf(charlie));
        assertEq(STARTING_BALANCE - 500, ourToken.balanceOf(bob));
    }
}
