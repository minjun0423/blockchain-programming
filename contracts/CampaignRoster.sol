pragma solidity ^0.8.0;

contract CampaignRoster {
    uint[] public campaignIds;

    function open(uint campaignId) external {
        campaignIds.push(campaignId);
    }

    function closeLast() external {
        require(campaignIds.length > 0);
        campaignIds.pop();
    }

    function swapRemove(uint index) external {
        campaignIds[index] = campaignIds[campaignIds.length - 1];
        campaignIds.pop();
    }
}
