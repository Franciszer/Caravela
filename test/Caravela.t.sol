// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Caravela.sol";
import "openzeppelin-contracts/contracts/mocks/ERC1155Mock.sol";
import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract ContractTest is Test {
    address constant MAKER_ADDRESS = address(1);
    address constant TAKER_ADDRESS = address(2);

    uint256 constant INITIAL_PRICE = 1000000;

    ERC1155Mock collection;
    ERC20Mock currency;
    Caravela marketplace;

    function setUp() public {
        collection = new ERC1155Mock("testCollectionURI");
        currency = new ERC20Mock(
            "testName",
            "testSymbol",
            TAKER_ADDRESS,
            INITIAL_PRICE
        );
        marketplace = new Caravela();
    }

    function testMakeSale() public {
        uint256 _id = 1;
        uint256 _value = 10;
        uint256 _price = 1000;

        collection.mint(MAKER_ADDRESS, _id, _value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            price: _price,
            collection: collection,
            currency: currency,
            value: _value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        assertEq(collection.balanceOf(address(marketplace), _id), _value);

        bytes32 uid = Order.compute_sale_uid(order);
        assertEq(marketplace.orders(uid), true);
    }

    function testTakeSale() public {
        uint256 _id = 1;
        uint256 _value = 10;
        uint256 _price = 1000;

        collection.mint(MAKER_ADDRESS, _id, _value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            price: _price,
            collection: collection,
            currency: currency,
            value: _value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), _price);

        marketplace.take_sale(order);
        assertEq(collection.balanceOf(TAKER_ADDRESS, _id), _value);

        bytes32 uid = Order.compute_sale_uid(order);
        assertEq(marketplace.orders(uid), false);
    }

    function testCurrencyTransfer() public {
        uint256 _id = 1;
        uint256 _value = 10;
        uint256 _price = 1000;

        collection.mint(MAKER_ADDRESS, _id, _value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            price: _price,
            collection: collection,
            currency: currency,
            value: _value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), _price);

        marketplace.take_sale(order);
        assertEq(collection.balanceOf(TAKER_ADDRESS, _id), _value);

        assertEq(currency.balanceOf(MAKER_ADDRESS), _price);
        assertEq(currency.balanceOf(TAKER_ADDRESS), INITIAL_PRICE - _price);
    }

    function testCancelSale() public {
        uint256 _id = 1;
        uint256 _value = 10;
        uint256 _price = 1000;

        collection.mint(MAKER_ADDRESS, _id, _value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            price: _price,
            collection: collection,
            currency: currency,
            value: _value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        marketplace.cancel_sale(order);
        assertEq(collection.balanceOf(MAKER_ADDRESS, _id), _value);

        bytes32 uid = Order.compute_sale_uid(order);
        assertEq(marketplace.orders(uid), false);
    }
}
