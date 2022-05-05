// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MutantNFT is IERC721Receiver,ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    ERC721Enumerable g_firstNftAddress;
    ERC721Enumerable g_secondNftAddress;
    ERC721Enumerable g_toxicNftAddress;

    uint256 public pos;	
	uint256 public mintSupply;
    mapping(uint256 => string) public _data;	
    mapping(uint256 => uint256) public _origin;

    
    mapping(string => string) public g_mutantPairs;
    event Purchase(uint256 _tokenId, uint256 _toxicId, uint256 _mutantId);
    constructor (ERC721Enumerable _firstNftAddress, ERC721Enumerable _secondNftAddress, ERC721Enumerable _toxicAddress) ERC721("CoinracerNFTCollection", "MutantNFT"){
        pos = 20000;
        mintSupply = 0;
        g_firstNftAddress = _firstNftAddress;
        g_secondNftAddress = _secondNftAddress;
        g_toxicNftAddress = _toxicAddress;
    }
    function purchase(uint256 _tokenId, uint256 _toxicId) external {
        ERC721Enumerable g_nftFactoryAddress;
        if(_tokenId > 5000)
            g_nftFactoryAddress = g_secondNftAddress;
        else
            g_nftFactoryAddress = g_firstNftAddress;
        
        require(g_nftFactoryAddress.ownerOf(_tokenId) == msg.sender, "You are not owner of this NFT");
        require(g_toxicNftAddress.ownerOf(_toxicId) == msg.sender, "You are not owner of this Toxic");
        require(g_nftFactoryAddress.getApproved(_tokenId) == address(this), "Require NFT ownership transfer approval");        
        require(g_toxicNftAddress.getApproved(_toxicId) == address(this), "Require Toxic ownership transfer approval");

        g_nftFactoryAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        g_toxicNftAddress.safeTransferFrom(msg.sender, address(this), _toxicId);

        pos = pos + 1;
        _safeMint(msg.sender, pos);
        _data[pos] = g_mutantPairs[g_nftFactoryAddress.tokenURI(_tokenId)];
        _origin[pos] = _tokenId;
        mintSupply += 1;
        emit Purchase(_tokenId, _toxicId, pos);
    }

    function mintByOwner(address addr, string memory data) external onlyOwner {
		pos = pos + 1;
		_safeMint(addr, pos);
		_data[pos] = data;
	}
    function getOriginTokenId(uint256 _mutantId) external view returns(uint256) {
        return _origin[_mutantId];
    }
    function withdrawNFT(address _to, uint256[] memory _tokenIds) external onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            ERC721Enumerable g_nftFactoryAddress;
            if(tokenId > 5000)
                g_nftFactoryAddress = g_secondNftAddress;
            else
                g_nftFactoryAddress = g_firstNftAddress;

            g_nftFactoryAddress.safeTransferFrom(address(this), _to, tokenId);
        }
    }

    function withdrawToxic(address _to, uint256[] memory _toxicIds) external onlyOwner {
        for(uint i = 0; i < _toxicIds.length; i++) {
            g_toxicNftAddress.safeTransferFrom(address(this), _to, _toxicIds[i]);
        }
    }
    function setPairs(string memory _old, string memory _mutant) external onlyOwner {
        g_mutantPairs[_old] = _mutant;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return _data[tokenId];
	}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}