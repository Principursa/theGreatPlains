pragma solidity ^0.8.7;

interface IRarity_skills {
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
    function skills_per_level(int _int, uint _class, uint _level) external view returns (uint points);
    function calculate_points_for_set(uint _class, uint8[36] memory _skills) external view returns (uint points);
    function class_skills(uint _class) external view returns (bool[36] memory _skills);
}
