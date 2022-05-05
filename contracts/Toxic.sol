// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/Rand.sol";

contract ToxicNFT is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    IERC20 g_craceToken;

    uint256 public pos;	
	uint256 public mintSupply;
    uint256 public g_initPrice;
    uint256 public g_percent;
    uint256 public g_totalSupply;
    	
    mapping(address => uint256) public g_toxicAmount;
    event mintToxic(address _user, uint256 _ticketAmount, uint256 _toxicAmount);
    constructor (IERC20 _tokenAddress) ERC721("CoinracerNFTCollection", "ToxicNFT"){
        pos = 0;
        g_craceToken = _tokenAddress;
        g_percent = 5;
        g_totalSupply = 3000;
    }
    function setInitPrice(uint256 _amount) external onlyOwner {
        g_initPrice = _amount;
    }
    function setPercent(uint256 _percent) external onlyOwner {
        g_percent = 100 / _percent;
    }
    function setTotalSupply(uint256 _amount) external onlyOwner {
        g_totalSupply = _amount;
    }
    function mint( uint256 _amount) external{
        require(_amount > 0, "Mint amount error!");
        uint256 price = _amount * g_initPrice;
        require(g_craceToken.balanceOf(msg.sender) >= price, "You don't have enough funds for buy tickets");
        require(g_totalSupply >= mintSupply , "Out of Supply");

        uint256 counter = 0;
        for(uint256 i = 0 ; i < _amount; i++) {
            uint256 seed = Rand.randInRange(1, 1000);
            if ((seed % g_percent) == 0) {
                pos = pos + 1;
                _safeMint(msg.sender, pos);
                counter = counter + 1;
            }
        }
        g_craceToken.safeTransferFrom(msg.sender, address(this), price);
        mintSupply = mintSupply + counter;
        emit mintToxic(msg.sender, _amount, counter);
    }
    function mintByOwner(address addr) external onlyOwner {
		pos = pos + 1;
		_safeMint(addr, pos);
	}
}