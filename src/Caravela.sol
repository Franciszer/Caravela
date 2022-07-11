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

    /// @dev create an order
    function make_sale(Order.ERC1155_sale memory order) external {
        bytes32 uid = Order.compute_order_uid(order);

        require(orders[uid] == false, "make_sale: order is already active");

        require(order.kind == Order.Kind.sale, "make_sale: order is not a sale");

        IERC1155 collection = order.collection;

        require(
            collection.isApprovedForAll(_msgSender(), address(this)),
            "make_sale: marketplace contract is not approved to handle tokens"
        );

        collection.safeTransferFrom(
            _msgSender(), address(this), order.id, order.amount, new bytes(0x0)
        );

        orders[uid] = true;
    }

    /// @dev fulfill an order
    function take_sale(Order.ERC1155_sale memory order) external {
        bytes32 uid = Order.compute_order_uid(order);

        require(orders[uid] == true, "take_sale: order is not active");
        require(order.kind == Order.Kind.sale, "take_sale: order is not a sale");

        IERC20 currency = order.currency;

        require(
            currency.allowance(_msgSender(), address(this)) >= order.value,
            "take_order: marketplace contract allowance is too small to buy token"
        );

        bool transaction_succeeded =
            currency.transferFrom(_msgSender(), order.emitter, order.value);

        require(
            transaction_succeeded == true, "take_sale: ERC20 token transfer failed"
        );

        order.collection.safeTransferFrom(
            address(this), _msgSender(), order.id, order.amount, new bytes(0x0)
        );
        orders[uid] = false;
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
