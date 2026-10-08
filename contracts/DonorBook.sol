pragma solidity ^0.8.0;

contract DonorBook {
    mapping(address => uint256) public donations;
    uint256 public totalDonated;

    function donate() external payable {
        require(msg.value > 0, "empty");

        donations[msg.sender] += msg.value;
        totalDonated += msg.value;
    }

    function refund(uint256 amount) external {
        require(amount <= donations[msg.sender]);

        donations[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
    }
}
