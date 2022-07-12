// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @dev Order logic
library Order {
    /// @dev peppers are added to the hash function when computing uids to make sure an attacker can't create two different orders with the same hash
    bytes32 constant SALE_PEPPER =
        0x35b7e35506707b7002359253b0246a5c6d757ac7d0ec84d97a0110a69d5d7029;

    bytes32 constant BATCH_SALE_PEPPER =
        0x1453f630445ab7eba43f4180b358c1f2761cface4f8447cfdfab5b8f12410d36;

    /// @dev order kind
    enum Kind {
        sale,
        batch_sale
    }

    /// @dev ERC1155 order
    /// @param id token id (see ERC1155)
    /// @param value amount of tokens the order (see ERC1155)
    /// @param price amount of tokens the order (see ERC1155)
    /// @param collection ERC1155 collecction contract
    /// @param currency ERC20 currency contract
    /// @param kind must be sale
    /// @param emitter type of order
    struct ERC1155Sale {
        uint256 id;
        uint256 value;
        uint256 price;
        IERC1155 collection;
        IERC20 currency;
        address emitter;
        Kind kind;
    }

    /// @dev ERC1155 order
    /// @param id token id (see ERC1155)
    /// @param value amount of tokens the order (see ERC1155)
    /// @param price amount of tokens the order (see ERC1155)
    /// @param collection ERC1155 collecction contract
    /// @param currency ERC20 currency contract
    /// @param kind must be batch_sale
    /// @param emitter type of order
    struct ERC1155BatchSale {
        uint256[] ids;
        uint256[] values;
        uint256 price;
        IERC1155 collection;
        IERC20 currency;
        address emitter;
        Kind kind;
    }

    /// @dev compute unique id of an ERC1155 sale
    /// @param order sale order
    /// @return uid unique id
    function compute_sale_uid(ERC1155Sale memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(SALE_PEPPER, order));
    }

    /// @dev compute unique id of an ERC1155 sale
    /// @param order sale order
    /// @return uid unique id
    function compute_batch_sale_uid(ERC1155BatchSale memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(BATCH_SALE_PEPPER, order));
    }
}
