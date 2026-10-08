pragma solidity ^0.8.0;
enum Category { EDU, HEALTH, ENV, ART }
contract CampaignRegistry {
  bytes32 public code;
  Category public category;
  uint public totalDonated;
  constructor(bytes32 campaignCode, Category categoryChoice) {
    code = campaignCode;
    category = categoryChoice;
  }
  function isHealth() external view
    returns (bool)
  { return category = Category.HEALTH; }
}
