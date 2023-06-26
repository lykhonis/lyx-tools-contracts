// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Subscriptions} from "../src/Subscriptions.sol";

contract Deploy is Script {
    function run() external {
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address authority = vm.envAddress("AUTHORITY_ADDRESS");

        address proxy = vm.envOr("CONTRACT_SUBSCRIPTIONS_ADDRESS", address(0));

        vm.broadcast(admin);
        Subscriptions subscriptions = new Subscriptions();

        if (proxy == address(0)) {
            vm.broadcast(admin);
            proxy = address(
                new TransparentUpgradeableProxy(
                    address(subscriptions),
                    admin,
                    abi.encodeWithSelector(
                        Subscriptions.initialize.selector,
                        owner,
                        authority
                    )
                )
            );
            console.log(
                string.concat(
                    "Subscriptions: deploy ",
                    Strings.toHexString(address(proxy))
                )
            );
        } else {
            vm.broadcast(admin);
            ITransparentUpgradeableProxy(proxy).upgradeTo(
                address(subscriptions)
            );
            console.log(
                string.concat(
                    "Subscriptions: upgrade ",
                    Strings.toHexString(address(proxy))
                )
            );
        }
    }
}

contract Configure is Script {
    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");
        address beneficiary = vm.envAddress("BENEFICIARY_ADDRESS");

        Subscriptions subscriptions = Subscriptions(
            payable(vm.envAddress("CONTRACT_SUBSCRIPTIONS_ADDRESS"))
        );

        vm.broadcast(owner);
        subscriptions.withdraw(beneficiary, address(subscriptions).balance);
    }
}
