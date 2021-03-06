//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IRarity.sol";
import "./interfaces/IAttributes.sol";
import "./interfaces/rarity_skills.sol";
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract TheRarityPlains is ERC721 {

    using Counters for Counters.Counter;
    using Strings for uint256;
    struct Monster {
        string name;
        string[3] drops;
        uint256 rarity;
    }
    Monster[] public monsters;
    string location = "The Great Plains";
    attributes attr; 

    constructor(address _rarityAddr,address _attrAddr,address _skillsContract) ERC721("TheRarityPlains", "TRP") {
        rarityContract = IRarity(_rarityAddr);
        skillsContract = IRarity_skills(_skillsContract);
        attr = attributes(_attrAddr);
        monsters.push(Monster("Slime",["Slime Shell","Slime Excretion","Slime Nucleus"],50));
        monsters.push(Monster("Wolf",["Wolf Skull","Wolf Teeth","Wolf Hide"],25));
        monsters.push(Monster("Horse",["Horse Hair","Horse Meat","Horse Hide"],15));
        monsters.push(Monster("Buffalo",["Buffalo Hide","Buffalo Meat","Buffalo Horns"],10));
    }

    uint256 private globalSeed;
    IRarity public rarityContract;
    IRarity_skills public skillsContract;
    mapping(uint256 => string) items;
    mapping (address=>mapping (uint256=>Hunt)) hunts;

    Counters.Counter public _tokenIdCounter;


    event HuntStarted(uint256 summonerId, address owner);
    event ItemAccquired(string loot);
    struct Hunt{
        uint256 timeInDays;
        uint256 initBlock;
        bool found;
        uint256 summonerId;
        address owner;
        int wisModifier;

    }

    //Returns random drop from random mob
    function returnDrop(Hunt memory hunt)internal returns(string memory drop){
        string memory _string = string(abi.encodePacked(hunt.summonerId, abi.encodePacked(hunt.owner), abi.encodePacked(hunt.initBlock), abi.encodePacked(globalSeed)));
        uint256 randint = _random(_string);
        int index =  int(randint % 100);
        globalSeed = uint256(index);
        index += hunt.wisModifier;
        if (90 < index ){

            return (monsters[3].drops[randint % monsters[3].drops.length]);

        }
        if (75 < index){
            return (monsters[2].drops[randint % monsters[2].drops.length]);

        }
        if (50 < index){
            return (monsters[1].drops[randint % monsters[1].drops.length]);

        }
        else{
            return (monsters[0].drops[randint % monsters[0].drops.length]);

        }


    }
    //Begins Hunt
    function startHunt(uint256 summonerId) public returns(uint256){
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your summoner");
        uint _class = rarityContract.class(summonerId);
        (,,,,uint256 _wis,) = attr.ability_scores(summonerId);
        (,,,uint256 summonerLevel) = rarityContract.summoner(summonerId);
        int _wisCheck =statCheck(_class,_wis,summonerLevel);
        int _skillCheck = int(skillCheck(summonerId));
        require(summonerLevel >= 2, "not level >= 2");
        require(hunts[msg.sender][summonerId].timeInDays == 0 || hunts[msg.sender][summonerId].found == true, "not empty or not fount yet"); //If empty or already found
        hunts[msg.sender][summonerId] = Hunt(2, block.timestamp, false, summonerId, msg.sender,_wisCheck + _skillCheck);
        emit HuntStarted(summonerId, msg.sender);
        return summonerId;
    }
    function base_attack_bonus_by_class(uint _class) public pure returns (uint attack) {
        if (_class == 1) {
            attack = 3;
        } else if (_class == 2) {
            attack = 2;
        } else if (_class == 3) {
            attack = 2;
        } else if (_class == 4) {
            attack = 4;
        } else if (_class == 5) {
            attack = 3;
        } else if (_class == 6) {
            attack = 3;
        } else if (_class == 7) {
            attack = 2;
        } else if (_class == 8) {
            attack = 4;
        } else if (_class == 9) {
            attack = 4;
        } else if (_class == 10) {
            attack = 2;
        } else if (_class == 11) {
            attack = 2;
        }
    }

    function base_attack_bonus_by_class_and_level(uint _class, uint _level) public pure returns (uint) {
        return _level * base_attack_bonus_by_class(_class) / 4;
    }


    function modifier_for_attribute(uint _attribute) public pure returns (int _modifier) {
        if (_attribute == 9) {
            return -1;
        }
        return (int(_attribute) - 10) / 2;
    }

    function skillCheck(uint256 summonerId) internal view returns(uint256){
        uint8[36] memory skills = skillsContract.get_skills(summonerId);
        uint8[7] memory idArray = [10,16,20,21,26,31,33];
        uint256 modif;
        for(uint8 j = 0; j < skills.length; j++){
            for(uint8 i = 0; i < idArray.length; i++){
                if(skills[j] == idArray[i]){
                    modif++;
                }

            }


        }
        return modif;

    }
    function statCheck(uint class, uint wis, uint level) internal pure returns(int){
       return  int(base_attack_bonus_by_class_and_level(class, level)) + modifier_for_attribute(wis);
    }

    //Completes Hunt
    function killCreature(uint256 summonerId) public returns(uint256){
        Hunt memory hunt = hunts[msg.sender][summonerId];
        require(!hunt.found && hunt.timeInDays > 0, "already discovered or not initialized");
        require(hunt.initBlock + (hunt.timeInDays * 1 days) < block.timestamp, "not finish yet");
        //mint erc721 based on pseudo random things
        (string memory _itemName) = returnDrop(hunt);
        uint256 newTokenId = safeMint(msg.sender);
        items[newTokenId] = _itemName;
        hunt.found = true;
        hunts[msg.sender][summonerId] = hunt;
        emit ItemAccquired(_itemName);
        return newTokenId;

    }



    //Gen random
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }


    //Is owner of summoner or is approved
    function _isApprovedOrOwnerOfSummoner(uint256 summonerId, address _owner) internal view virtual returns (bool) {
        //_owner => expected owner
        address spender = address(this);
        address owner = rarityContract.ownerOf(summonerId);
        return (owner == _owner || rarityContract.getApproved(summonerId) == spender || rarityContract.isApprovedForAll(owner, spender));
    }

    //Mint a new ERC721
    function safeMint(address to) internal returns (uint256){
        uint256 counter = _tokenIdCounter.current();
        _safeMint(to, counter);
        _tokenIdCounter.increment();
        return counter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[5] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("Name:", " ", items[tokenId]));
        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(abi.encodePacked("Location:", " ", location));


        parts[4] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2],parts[3],parts[4]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "loot #', tokenId.toString(), '", "description": "You have bested the plains, to the victor go the spoils", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }


    //View your loot
    function loot(uint tokenId) external view returns (string memory _itemName) {
        _itemName = items[tokenId];
    }

}