// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Caravela.sol";
import "openzeppelin-contracts/contracts/mocks/ERC1155Mock.sol";
import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract ContractTest is Test {
    address constant MAKER_ADDRESS = address(1);
    address constant TAKER_ADDRESS = address(2);

    uint256 constant INITIAL_TAKER_BALANCE = 1000000;

    ERC1155Mock collection;
    ERC20Mock currency;
    Caravela marketplace;

    function setUp() public {
        collection = new ERC1155Mock("testCollectionURI");
        currency = new ERC20Mock(
            "testName",
            "testSymbol",
            TAKER_ADDRESS,
            INITIAL_TAKER_BALANCE
        );
        marketplace = new Caravela();
    }

    function testSale() public {
        uint256 id = 1;
        uint256 value = 10;
        uint256 price = 1000;

        collection.mint(MAKER_ADDRESS, id, value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: id,
            price: price,
            collection: collection,
            currency: currency,
            value: value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        assertEq(collection.balanceOf(address(marketplace), id), value);

        bytes32 uid = Order.compute_sale_uid(order);
        assertEq(marketplace.orders(uid), true);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), price);

        marketplace.take_sale(order);
        assertEq(collection.balanceOf(TAKER_ADDRESS, id), value);

        assertEq(marketplace.orders(uid), false);

        uint256 expected_taker_balance = INITIAL_TAKER_BALANCE - price;
        assertEq(expected_taker_balance, currency.balanceOf(TAKER_ADDRESS));

        uint256 expected_maker_balance = price;
        assertEq(expected_maker_balance, currency.balanceOf(MAKER_ADDRESS));
    }

    function testCancelSale() public {
        uint256 id = 1;
        uint256 value = 10;
        uint256 price = 1000;

        collection.mint(MAKER_ADDRESS, id, value, new bytes(0));

        Order.ERC1155Sale memory order = Order.ERC1155Sale({
            emitter: MAKER_ADDRESS,
            id: id,
            price: price,
            collection: collection,
            currency: currency,
            value: value,
            kind: Order.Kind.sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_sale(order);

        marketplace.cancel_sale(order);
        assertEq(collection.balanceOf(MAKER_ADDRESS, id), value);

        bytes32 uid = Order.compute_sale_uid(order);
        assertEq(marketplace.orders(uid), false);
    }

    function testBatchSale() public {
        uint256[] memory ids = new uint256[](3);
        uint256[] memory values = new uint256[](3);
        uint256 price = 1000;

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;

        values[0] = (10);
        values[1] = (20);
        values[2] = (40);

        collection.mintBatch(MAKER_ADDRESS, ids, values, new bytes(0));

        Order.ERC1155BatchSale memory order = Order.ERC1155BatchSale({
            emitter: MAKER_ADDRESS,
            ids: ids,
            price: price,
            collection: collection,
            currency: currency,
            values: values,
            kind: Order.Kind.batch_sale
        });

        vm.startPrank(MAKER_ADDRESS);
        collection.setApprovalForAll(address(marketplace), true);
        marketplace.make_batch_sale(order);

        bytes32 uid = Order.compute_batch_sale_uid(order);
        assertEq(marketplace.orders(uid), true);

        vm.stopPrank();

        vm.startPrank(TAKER_ADDRESS);

        currency.approve(address(marketplace), price);

        marketplace.take_batch_sale(order);

        for (uint256 i = 0; i < 3; i++) {
            assertEq(collection.balanceOf(TAKER_ADDRESS, ids[i]), values[i]);
        }

        assertEq(marketplace.orders(uid), false);

        uint256 expected_taker_balance = INITIAL_TAKER_BALANCE - price;
        assertEq(expected_taker_balance, currency.balanceOf(TAKER_ADDRESS));

        uint256 expected_maker_balance = price;
        assertEq(expected_maker_balance, currency.balanceOf(MAKER_ADDRESS));
    }
}
