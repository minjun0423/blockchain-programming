struct DonorProfile {
    string name;
    uint256 score;
}

contract ProfileBook {
    mapping(address => DonorProfile) public profiles;

    function join(string calldata donorName) external {
        profiles[msg.sender] = DonorProfile(donorName, 0);
    }

    function addScore(uint256 pointsToAdd) external {
        profiles[msg.sender].score += pointsToAdd;
    }
}
