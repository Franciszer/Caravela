// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/SigUtils.sol";
import "src/ERC1155Permit.sol";

contract ERC1155PermitTest is Test {
    ERC1155Permit internal collection;
    SigUtils internal sigUtils;

    uint256 internal owner_private_key;

    address internal owner;
    address internal operator;

    uint256 id;
    uint256 amount;

    function setUp() public {
        operator = address(this);

        collection = new ERC1155Permit(operator, "name", "symbol");
        sigUtils = new SigUtils(collection.DOMAIN_SEPARATOR());

        owner_private_key = 0xA11CE;
        owner = vm.addr(owner_private_key);

        id = 1;
        amount = 10;
        collection.mint(owner, id, amount);
    }

    function testMint() public {
        address user = address(0x1);

        collection.mint(user, id, amount);
    }

    function testPermitTransferSingle() public {
        SigUtils.PermitTransferSingle memory permit = SigUtils
            .PermitTransferSingle(owner, operator, id, amount, 0, 1 days);

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner_private_key, digest);

        collection.permit(
            permit.owner,
            permit.operator,
            permit.id,
            permit.amount,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(true, collection.isApprovedForAll(owner, operator));
    }
}
