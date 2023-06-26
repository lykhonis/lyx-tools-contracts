// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Subscriptions is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    error DispositionFailure(address beneficiary, uint256 amount);
    error UnauthorizedPurchase(
        address subscriber,
        uint256 price,
        uint256 durationSeconds
    );

    event ValueReceived(address indexed sender, uint256 indexed value);
    event ValueWithdrawn(address indexed recipient, uint256 indexed value);
    event SubscriptionPurchased(
        address subscriber,
        uint256 price,
        uint256 expirationTime
    );

    // subscriber => expiration time (seconds)
    mapping(address => uint256) private _subscriptions;
    address public authority;

    function initialize(
        address owner_,
        address authority_
    ) external initializer {
        __ReentrancyGuard_init();
        _transferOwnership(owner_);
        authority = authority_;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit ValueReceived(msg.sender, msg.value);
        }
    }

    function withdraw(
        address recipient,
        uint256 amount
    ) external nonReentrant onlyOwner {
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert DispositionFailure(recipient, amount);
        }
        emit ValueWithdrawn(recipient, amount);
    }

    function getExpirationTime(
        address subscriber
    ) external view returns (uint256) {
        return _subscriptions[subscriber];
    }

    function purchase(
        address subscriber,
        uint256 durationSeconds,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                block.chainid,
                msg.value,
                subscriber,
                durationSeconds
            )
        );
        if (ECDSA.recover(hash, v, r, s) != authority) {
            revert UnauthorizedPurchase(subscriber, msg.value, durationSeconds);
        }
        uint256 expirationTime = _subscriptions[subscriber];
        if (expirationTime == 0) {
            expirationTime = block.timestamp;
        }
        expirationTime += durationSeconds;
        _subscriptions[subscriber] = expirationTime;
        emit SubscriptionPurchased(subscriber, msg.value, expirationTime);
    }
}
