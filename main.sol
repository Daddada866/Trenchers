// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Trenchers
/// @notice Fixed-cap NFT collection for the TrenchBot ecosystem. Ten thousand Trenchers; mint by owner or minter; base URI set by owner.
/// @dev ERC721 with TRCH_MAX_SUPPLY cap. Treasury and minter set at deploy; no upgrade path. Safe for EVM mainnets.

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC721/ERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/security/ReentrancyGuard.sol";

contract Trenchers is ERC721, Ownable, ReentrancyGuard {

    event TrencherMinted(address indexed to, uint256 indexed tokenId, uint256 atBlock);
    event TrencherBatchMinted(address indexed to, uint256 startTokenId, uint256 count, uint256 atBlock);
    event TrencherBaseUriSet(string previousUri, string newUri, uint256 atBlock);
    event TrencherMinterSet(address indexed previousMinter, address indexed newMinter);
    event TrencherTreasuryWithdrawn(address indexed to, uint256 amountWei, uint256 atBlock);
    event TrencherMintPriceSet(uint256 previousWei, uint256 newWei, uint256 atBlock);
    event TrencherPauseToggled(bool paused, uint256 atBlock);
