// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";

contract ERC1155Permit is ERC1155, Owned {
    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    mapping(uint256 => string) uris;

    /*//////////////////////////////////////////////////////////////
                            PERMIT STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 constant PERMIT_TRANSFER_SINGLE_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address owner,
        string memory _name,
        string memory _symbol
    ) Owned(owner) {
        name = _name;
        symbol = _symbol;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                             ERC-1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _batchMint(to, ids, amounts, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        isApprovedForAll[owner][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    function setURI(uint256 id, string memory _uri) public {
        uris[id] = _uri;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address operator,
        uint256 id,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        _computePermitTransferSingle(
                            owner,
                            operator,
                            id,
                            amount,
                            deadline
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            _setApprovalForAll(owner, operator, true);
        }

        emit ApprovalForAll(owner, operator, true);
    }

    function _computePermitTransferSingle(
        address owner,
        address operator,
        uint256 id,
        uint256 amount,
        uint256 deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TRANSFER_SINGLE_TYPEHASH,
                    owner,
                    operator,
                    id,
                    amount,
                    nonces[owner]++,
                    deadline
                )
            );
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}
