// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleDonation {
    address payable public beneficiary;
    mapping(address => uint256) public donations;

    constructor(address payable initialBeneficiary) {
        require(initialBeneficiary != address(0));
        beneficiary = initialBeneficiary;
    }

    function donate() external payable {
        donations[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(msg.sender == beneficiary);

        uint256 balance = address(this).balance;
        require(balance > 0);

        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
