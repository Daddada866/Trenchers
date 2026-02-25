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

    error TRCH_ZeroAddress();
    error TRCH_MaxSupplyReached();
    error TRCH_Paused();
    error TRCH_NotMinter();
    error TRCH_TransferFailed();
    error TRCH_WithdrawZero();
    error TRCH_InsufficientMintPayment();
    error TRCH_BatchTooLarge();
    error TRCH_ZeroCount();

    uint256 public constant TRCH_MAX_SUPPLY = 10_000;
    uint256 public constant TRCH_BATCH_MINT_CAP = 32;
    uint256 public constant TRCH_DOMAIN_SALT = 0x7e3a9c1f5b8d2e4a6c0f3b5d7e9a1c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8;

    address public immutable trenchTreasury;
    address public trenchMinter;
    uint256 public mintPriceWei;
    bool public trenchPaused;
    string private _baseTokenURI;
    uint256 public totalMinted;

    modifier whenNotPaused() {
        if (trenchPaused) revert TRCH_Paused();
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != trenchMinter && msg.sender != owner()) revert TRCH_NotMinter();
        _;
    }

    constructor() ERC721("Trenchers", "TRCH") Ownable(msg.sender) {
        trenchTreasury = address(0x4a8c2e6f1b3d5a7c9e0f2b4d6a8c0e2f4a6b8d0e2);
        trenchMinter = address(0x5b9d3f7a1c4e6f8b0d2a4c6e8f0b2d4f6a8c0e2);
        mintPriceWei = 0.005 ether;
        _baseTokenURI = "https://trenchers.example.com/metadata/";
    }

    function setPaused(bool paused) external onlyOwner {
        trenchPaused = paused;
        emit TrencherPauseToggled(paused, block.number);
    }

    function setMinter(address newMinter) external onlyOwner {
        if (newMinter == address(0)) revert TRCH_ZeroAddress();
        address prev = trenchMinter;
        trenchMinter = newMinter;
        emit TrencherMinterSet(prev, newMinter);
    }

    function setBaseURI(string calldata newUri) external onlyOwner {
        string memory prev = _baseTokenURI;
        _baseTokenURI = newUri;
        emit TrencherBaseUriSet(prev, newUri, block.number);
    }

    function setMintPriceWei(uint256 newPriceWei) external onlyOwner {
        uint256 prev = mintPriceWei;
        mintPriceWei = newPriceWei;
        emit TrencherMintPriceSet(prev, newPriceWei, block.number);
    }

    function mint(address to) external payable onlyMinter whenNotPaused nonReentrant returns (uint256 tokenId) {
        if (to == address(0)) revert TRCH_ZeroAddress();
        if (totalMinted >= TRCH_MAX_SUPPLY) revert TRCH_MaxSupplyReached();
        if (msg.value < mintPriceWei) revert TRCH_InsufficientMintPayment();
        tokenId = totalMinted;
        totalMinted += 1;
        _safeMint(to, tokenId);
        if (msg.value > 0) {
            (bool ok,) = trenchTreasury.call{value: msg.value}("");
            if (!ok) revert TRCH_TransferFailed();
        }
        emit TrencherMinted(to, tokenId, block.number);
        return tokenId;
    }

    function mintBatch(address to, uint256 count) external payable onlyMinter whenNotPaused nonReentrant {
        if (to == address(0)) revert TRCH_ZeroAddress();
        if (count == 0) revert TRCH_ZeroCount();
        if (count > TRCH_BATCH_MINT_CAP) revert TRCH_BatchTooLarge();
        if (totalMinted + count > TRCH_MAX_SUPPLY) revert TRCH_MaxSupplyReached();
        if (msg.value < mintPriceWei * count) revert TRCH_InsufficientMintPayment();
        uint256 startId = totalMinted;
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, totalMinted);
            totalMinted += 1;
        }
        if (msg.value > 0) {
            (bool ok,) = trenchTreasury.call{value: msg.value}("");
            if (!ok) revert TRCH_TransferFailed();
        }
        emit TrencherBatchMinted(to, startId, count, block.number);
    }

    function mintByOwner(address to, uint256 count) external onlyOwner whenNotPaused nonReentrant {
        if (to == address(0)) revert TRCH_ZeroAddress();
        if (count == 0) revert TRCH_ZeroCount();
        if (count > TRCH_BATCH_MINT_CAP) revert TRCH_BatchTooLarge();
        if (totalMinted + count > TRCH_MAX_SUPPLY) revert TRCH_MaxSupplyReached();
        uint256 startId = totalMinted;
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, totalMinted);
            totalMinted += 1;
        }
        emit TrencherBatchMinted(to, startId, count, block.number);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }
}

