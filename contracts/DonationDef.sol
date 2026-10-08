struct Donation {
    address donor;
    uint256 amount;
    uint64 timestamp;
    uint256 campaignId;
}

contract LatestDonation {
    Donation public latest;

    function setLatest() external {
        latest = Donation(msg.sender, 1 ether, 0, 7);
    }
}
