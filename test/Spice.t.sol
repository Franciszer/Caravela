// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Caravela.sol";
import "src/Spice.sol";

contract ContractTest is Test {
    Spice public currency;
    uint256 constant INITIAL_BALANCE = 0xFFFF;
    address public admin;

    function setUp() public {
        admin = address(this);

        currency = new Spice("name", "symbol");

        currency.mint(admin, INITIAL_BALANCE);
    }

    function testMint() public {
        uint256 expected_balance = INITIAL_BALANCE;

        assertEq(expected_balance, currency.balanceOf(admin));
    }

	function testTransferPermit() public {
		
	}
}
