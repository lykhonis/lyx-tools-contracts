// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/Subscriptions.sol";

contract SubscriptionsTest is Test {
    event ValueReceived(address indexed sender, uint256 indexed value);
    event ValueWithdrawn(address indexed recipient, uint256 indexed value);
    event SubscriptionPurchased(
        address subscriber,
        uint256 price,
        uint256 expirationTime
    );

    Subscriptions public subscriptions;
    address public admin;
    address public owner;
    address public authority;
    uint256 public authorityKey;

    function setUp() public {
        admin = vm.addr(1);
        owner = vm.addr(2);

        authorityKey = 3;
        authority = vm.addr(authorityKey);

        subscriptions = Subscriptions(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(new Subscriptions()),
                        admin,
                        abi.encodeWithSelector(
                            Subscriptions.initialize.selector,
                            owner,
                            authority
                        )
                    )
                )
            )
        );
    }

    function test_Initialize() public {
        assertEq(owner, subscriptions.owner());
        assertEq(authority, subscriptions.authority());
    }

    function testFuzz_purchase(
        address subscriber,
        uint256 price,
        uint256 durationSeconds
    ) public {
        vm.assume(type(uint256).max - block.timestamp >= durationSeconds);

        address account = vm.addr(100);

        bytes32 hash = keccak256(
            abi.encodePacked(
                address(subscriptions),
                block.chainid,
                price,
                subscriber,
                durationSeconds
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorityKey, hash);

        vm.deal(address(account), price);
        vm.prank(account);
        vm.expectEmit(address(subscriptions));
        emit SubscriptionPurchased(
            subscriber,
            price,
            block.timestamp + durationSeconds
        );
        subscriptions.purchase{value: price}(
            subscriber,
            durationSeconds,
            v,
            r,
            s
        );

        uint256 expirationTime = subscriptions.getExpirationTime(subscriber);
        assertEq(expirationTime, block.timestamp + durationSeconds);
        assertEq(address(subscriptions).balance, price);
    }

    function testFuzz_withdraw(uint256 amount) public {
        address recipient = vm.addr(100);

        vm.deal(address(subscriptions), amount);

        vm.prank(owner);
        vm.expectEmit(address(subscriptions));
        emit ValueWithdrawn(recipient, amount);
        subscriptions.withdraw(recipient, amount);
        assertEq(address(recipient).balance, amount);
    }
}
