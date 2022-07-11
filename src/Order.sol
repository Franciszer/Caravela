// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @dev Order logic
library Order {
    bytes32 constant PEPPER =
        0x35b7e35506707b7002359253b0246a5c6d757ac7d0ec84d97a0110a69d5d7029;

    /// @dev order kind
    enum Kind {sale}

    /// @dev ERC1155 order
    /// @param id id of the order (see ERC1155)
    /// @param value value of the order (see ERC1155)
    /// @param collection ERC1155 collecction contract
    /// @param kind type of order
    struct ERC1155_sale {
        uint256 id;
        uint256 value;
        uint256 amount;
        IERC1155 collection;
        IERC20 currency;
        address emitter;
        Kind kind;
    }

    /// @dev compute unique id of an ERC1155 order
    /// @param order order
    /// @return uid order uid
    function compute_order_uid(ERC1155_sale memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(PEPPER, order));
    }
}
