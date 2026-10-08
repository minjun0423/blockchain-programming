// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Counter {
    uint256 public count;
    int256 public delta;

    function inc(uint256 n)
        public
    {
        count += n;
    }

    function dec(uint256 n)
        public
    {
        require(n <= count);
        count -= n;
    }
}
