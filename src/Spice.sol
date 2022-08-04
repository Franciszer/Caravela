// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Spice is ERC20PresetMinterPauser, ERC20Permit {
    constructor(string memory name_, string memory symbol_)
        ERC20PresetMinterPauser	(name_, symbol_)
        ERC20Permit(name_)
    {}

	function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }

	function permit_typehash() external view {
		return 
	}
}
