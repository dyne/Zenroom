// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^3.1.0
pragma solidity ^0.6.0;

import "./3.1.0/contracts/token/ERC1155/ERC1155.sol";

contract zen1155 is ERC1155 {


    constructor() public ERC1155("http://example.com:8080/api/tokens/") {
    }


    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
//        onlyOwner
    {
        _mint(account, id, amount, data);
    }


}
