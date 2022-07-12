// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import
    "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";
import "./Order.sol";

/// @title Caravela
/// @author Franciszer
/// @notice ERC1155 marketplace
contract Caravela is Context, ERC1155Receiver {
    using Order for *;

    /// @dev order status indexed by the uid of each order
    mapping(bytes32 => bool) public orders;

    event MadeERC1155Sale(bytes32 indexed uid, Order.ERC1155Sale order);

    event TookERC1155Sale(bytes32 indexed uid, Order.ERC1155Sale order);

    event CancelledERC1155Sale(bytes32 indexed uid, Order.ERC1155Sale order);

    event MadeERC1155BatchSale(bytes32 indexed uid, Order.ERC1155BatchSale order);

    event TookERC1155BatchSale(bytes32 indexed uid, Order.ERC1155BatchSale order);

    event CancelledERC1155BatchSale(bytes32 indexed uid, Order.ERC1155BatchSale order);

    /// @dev make ERC1155 sale
    /// @param order order
    function make_sale(Order.ERC1155Sale memory order) external {
        bytes32 uid = Order.compute_sale_uid(order);

        require(orders[uid] == false, "make_sale: order is already active");

        require(order.kind == Order.Kind.sale, "make_sale: order is not a sale");

        require(
            _msgSender() == order.emitter,
            "make_sale: emitter is not the owner of the token"
        );

        IERC1155 collection = order.collection;

        require(
            collection.isApprovedForAll(_msgSender(), address(this)),
            "make_sale: marketplace contract is not approved to handle tokens"
        );

        collection.safeTransferFrom(
            _msgSender(), address(this), order.id, order.value, new bytes(0x0)
        );

        orders[uid] = true;

        emit MadeERC1155Sale(uid, order);
    }

    /// @dev make ERC1155 sale
    /// @param order order
    function make_batch_sale(Order.ERC1155BatchSale memory order) external {
        bytes32 uid = Order.compute_batch_sale_uid(order);

        require(orders[uid] == false, "make_batch_sale: order is already active");

        require(order.kind == Order.Kind.batch_sale, "make_batch_sale: order is not a sale");

        require(
            _msgSender() == order.emitter,
            "make_batch_sale: emitter is not the owner of the token"
        );

        IERC1155 collection = order.collection;

        require(
            collection.isApprovedForAll(_msgSender(), address(this)),
            "make_batch_sale: marketplace contract is not approved to handle tokens"
        );

        collection.safeBatchTransferFrom(
            _msgSender(), address(this), order.ids, order.values, new bytes(0x0)
        );

        orders[uid] = true;

        emit MadeERC1155BatchSale(uid, order);
    }

    /// @dev take ERC1155 sale
    /// @param order order
    function take_sale(Order.ERC1155Sale memory order) external {
        bytes32 uid = Order.compute_sale_uid(order);

        require(orders[uid] == true, "take_sale: order is not active");
        require(order.kind == Order.Kind.sale, "take_sale: order is not a sale");

        IERC20 currency = order.currency;

        require(
            currency.allowance(_msgSender(), address(this)) >= order.price,
            "take_order: marketplace contract allowance is too small to buy token"
        );

        bool transaction_succeeded =
            currency.transferFrom(_msgSender(), order.emitter, order.price);

        require(
            transaction_succeeded == true, "take_sale: ERC20 token transfer failed"
        );

        order.collection.safeTransferFrom(
            address(this), _msgSender(), order.id, order.value, new bytes(0x0)
        );

        orders[uid] = false;

        emit TookERC1155Sale(uid, order);
    }

    /// @dev take ERC1155 sale
    /// @param order order
    function take_batch_sale(Order.ERC1155BatchSale memory order) external {
        bytes32 uid = Order.compute_batch_sale_uid(order);

        require(orders[uid] == true, "take_sale: order is not active");
        require(order.kind == Order.Kind.batch_sale, "take_sale: order is not a sale");

        IERC20 currency = order.currency;

        require(
            currency.allowance(_msgSender(), address(this)) >= order.price,
            "take_order: marketplace contract allowance is too small to buy token"
        );

        bool transaction_succeeded =
            currency.transferFrom(_msgSender(), order.emitter, order.price);

        require(
            transaction_succeeded == true, "take_sale: ERC20 token transfer failed"
        );

        order.collection.safeBatchTransferFrom(
            address(this), _msgSender(), order.ids, order.values, new bytes(0x0)
        );

        orders[uid] = false;

        emit TookERC1155BatchSale(uid, order);
    }

    /// @dev cancel ERC1155 sale
    /// @param order order
    function cancel_sale(Order.ERC1155Sale memory order) external {
        bytes32 uid = Order.compute_sale_uid(order);

        require(orders[uid] == true, "cancel_sale: order is not active");

        require(
            order.kind == Order.Kind.sale, "cancel_sale: order is not a sale"
        );

        require(
            order.emitter == _msgSender(),
            "cancel_sale: you are not emitter of this sale"
        );

        order.collection.safeTransferFrom(
            address(this), order.emitter, order.id, order.value, new bytes(0x0)
        );

        orders[uid] = false;

        emit CancelledERC1155Sale(uid, order);
    }

    /// @dev cancel ERC1155 sale
    /// @param order order
    function cancel_batch_sale(Order.ERC1155BatchSale memory order) external {
        bytes32 uid = Order.compute_batch_sale_uid(order);

        require(orders[uid] == true, "cancel_sale: order is not active");

        require(
            order.kind == Order.Kind.batch_sale, "cancel_sale: order is not a sale"
        );

        require(
            order.emitter == _msgSender(),
            "cancel_sale: you are not emitter of this sale"
        );

        order.collection.safeBatchTransferFrom(
            address(this), order.emitter, order.ids, order.values, new bytes(0x0)
        );

        orders[uid] = false;

        emit CancelledERC1155BatchSale(uid, order);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        pure
        returns (bytes4)
    {
        operator;
        from;
        id;
        value;
        data;
        return bytes4(
            keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        pure
        returns (bytes4)
    {
        operator;
        from;
        ids;
        values;
        data;
        return bytes4(
            keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
        );
    }
}
