// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Caravela.sol";
import "openzeppelin-contracts/contracts/mocks/ERC1155Mock.sol";
import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract ContractTest is Test {
    address constant MAKER_ADDRESS = address(1);
    address constant TAKER_ADDRESS = address(2);

    uint256 constant INITIAL_VALUE = 1000000;

    ERC1155Mock collection;
    ERC20Mock currency;
    Caravela marketplace;

    function setUp() public {
        collection = new ERC1155Mock("testCollectionURI");
        currency = new ERC20Mock(
            "testName",
            "testSymbol",
            TAKER_ADDRESS,
            INITIAL_VALUE
        );
        marketplace = new Caravela();
    }

    function testMakeSale() public {
        uint256 _id = 1;
        uint256 _amount = 10;
        uint256 _value = 1000;

        collection.mint(MAKER_ADDRESS, _id, _amount, new bytes(0));

        Order.ERC1155_sale memory order = Order.ERC1155_sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            value: _value,
            collection: collection,
            currency: currency,
            amount: _amount,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        assertEq(collection.balanceOf(address(marketplace), _id), _amount);
    }

    function testTakeSale() public {
        uint256 _id = 1;
        uint256 _amount = 10;
        uint256 _value = 1000;

        collection.mint(MAKER_ADDRESS, _id, _amount, new bytes(0));

        Order.ERC1155_sale memory order = Order.ERC1155_sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            value: _value,
            collection: collection,
            currency: currency,
            amount: _amount,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), _value);

        marketplace.take_sale(order);
        assertEq(collection.balanceOf(TAKER_ADDRESS, _id), _amount);
    }

    function testCurrencyTransfer() public {
        uint256 _id = 1;
        uint256 _amount = 10;
        uint256 _value = 1000;

        collection.mint(MAKER_ADDRESS, _id, _amount, new bytes(0));

        Order.ERC1155_sale memory order = Order.ERC1155_sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            value: _value,
            collection: collection,
            currency: currency,
            amount: _amount,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), _value);

        marketplace.take_sale(order);
        assertEq(collection.balanceOf(TAKER_ADDRESS, _id), _amount);

        assertEq(currency.balanceOf(MAKER_ADDRESS), _value);
        assertEq(currency.balanceOf(TAKER_ADDRESS), INITIAL_VALUE - _value);
    }

    function testCancelSale() public {
        uint256 _id = 1;
        uint256 _amount = 10;
        uint256 _value = 1000;

        collection.mint(MAKER_ADDRESS, _id, _amount, new bytes(0));

        Order.ERC1155_sale memory order = Order.ERC1155_sale({
            emitter: MAKER_ADDRESS,
            id: _id,
            value: _value,
            collection: collection,
            currency: currency,
            amount: _amount,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        marketplace.cancel_sale(order);
        assertEq(collection.balanceOf(MAKER_ADDRESS, _id), _amount);
    }
}
