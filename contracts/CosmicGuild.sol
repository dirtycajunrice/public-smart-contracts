// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CosmicGuild is ERC721Enumerable,ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant NFT_MAX = 11664;

    IERC20 private MAGIC ;

    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";
    // Epoch time set Sunday, February 20, 2022 3:00:00 PM GMT
    uint256 private _startTime = 1645369200;
    address private withdrawalWallet;

    //Land Array
    mapping(uint256 => uint256) public landPrice;
    mapping(address => uint256) public whitelistUser;
    uint256[] public soldTokens;
    // address[] public whitelistUser;

    event SetStartTime(uint256 _timestamp);

    function isLandAvailable(uint256 tokenId)
        public view
        returns (bool) {
            return (!_exists(tokenId)) && (landPrice[tokenId] != 0);
    }

    modifier isLandAvailableMod(uint256 tokenId) {
        require(isLandAvailable(tokenId), "Token is not Land or Sold out ");
        _;
    }

    modifier isLive() {
        require(block.timestamp >= (_startTime - 86400), "Sale hasn't started");
        _;
    }

    modifier canPurchase() {
        uint256 PURCHASE_LIMIT = (block.timestamp < _startTime ) ? 10 : 75; // if it's presale then limit is 10 else 75
        require(
            balanceOf(msg.sender) < PURCHASE_LIMIT,
            "Requested number exceeds purchase limit"
        );
        _;
    }

    modifier isWhiteListed(){
        uint256 startTime = _startTime;
        if(block.timestamp >= startTime) {
             // Everyone can purchase
        }else if(block.timestamp >= (startTime - 28800)){
            // Tier 1 (before 8 hour of sale start)
            require(whitelistUser[msg.sender] >=1,"Tier 1 or above allowed");
        }else if(block.timestamp >= (startTime - 56600)){
            // Tier 2 (before 16 hour of sale)
            require(whitelistUser[msg.sender] >=2,"Tier 2 or above allowed");
        }else if(block.timestamp >= (startTime - 86400)){
            // Tier 3 (before 24 hour of sale)
            require(whitelistUser[msg.sender] >=3,"Tier 3 or above allowed");
        }else require(false,"Sale is not Start yet");
        _;
    }


    event Purchase(address receiver, uint256 tokenId);

    constructor(string memory name, string memory symbol, address wallet, address magic)
        ERC721(name, symbol)
    {
        require(wallet != address(0),"Address Should be real");
        require(magic != address(0),"MAGIC Address Should be real");
        withdrawalWallet = wallet;
        MAGIC = IERC20(magic);

    }


    function purchase(uint256 tokenId)
        external
        isLive
        isLandAvailableMod(tokenId)
        canPurchase
        isWhiteListed
        nonReentrant
    {
        require(NFT_MAX >= tokenId, "TokenID not within range");

        bool _success = MAGIC.transferFrom(msg.sender,withdrawalWallet,landPrice[tokenId]);
        require(_success,"Transfer is not Done");
        soldTokens.push(tokenId);
        _safeMint(msg.sender, tokenId);
        emit Purchase(msg.sender, tokenId);
    }
    

    function soldTokensAll() external view returns( uint256 [] memory) {
        return soldTokens;
    }

    function setLandPriceArr(uint256 price,uint256[] memory arr) external onlyOwner {
        for(uint i = 0 ; i < arr.length;i++){
            landPrice[arr[i]] = price;
        }
    }

    function setWhiteListArr(uint tier,address[] memory arr) external onlyOwner {
        for(uint i = 0 ; i < arr.length;i++){
            // whitelistUser.push(_arr[i]);
            whitelistUser[arr[i]] = tier;
        }
    }

    function setStartTime(uint256 newTime) external onlyOwner {
        _startTime = newTime;
        emit SetStartTime(newTime);
    }

    function withdraw() external {
        require(msg.sender == withdrawalWallet, "Only withdrawal wallet can access");
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _tokenBaseURI = uri;
    }

    function setRevealedBaseURI(string calldata _revealedBaseURI)
        external
        onlyOwner
    {
        _tokenRevealedBaseURI = _revealedBaseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");

        /// @dev Convert string to bytes so we can check if it's empty or not.
        return
            bytes(_tokenRevealedBaseURI).length > 0
                ? string(
                    abi.encodePacked(_tokenRevealedBaseURI, _tokenId.toString())
                )
                : _tokenBaseURI;
    }
}