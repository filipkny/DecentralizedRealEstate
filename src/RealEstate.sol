 
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract RealEstate is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    mapping(uint256 => string) _tokenURIs;

    constructor() ERC721("Real estate", "REAL") {

    }

    function mint(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _tokenURIs[newItemId] = tokenURI;

        return newItemId;
    }

}
