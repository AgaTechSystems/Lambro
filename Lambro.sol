pragma solidity ^0.8.23;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Lambro
 * @notice An ERC20 token with a capped supply, ownership privileges, and pausable transactions.
 * @dev This token extends the ERC20 standard with a fixed cap and adds the ability to pause/resume transactions.
 * The contract also includes a recovery mechanism for ERC20 tokens sent by mistake.
 */
contract Lambro is ERC20, ERC20Capped, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * (10 ** 18);

    /// @notice Emitted when tokens are minted.
    /// @param to The address that received the minted tokens.
    /// @param amount The amount of tokens minted.
    event TokenMinted(address indexed to, uint256 amount);

    /// @notice Emitted when token transactions are paused.
    /// @param account The address that initiated the pause.
    event TokenPaused(address account);

    /// @notice Emitted when token transactions are unpaused.
    /// @param account The address that initiated the unpause.
    event TokenUnpaused(address account);

    /// @notice Emitted when tokens sent by mistake are retrieved.
    /// @param token The address of the token retrieved.
    /// @param to The recipient of the retrieved tokens.
    /// @param amount The amount of tokens retrieved.
    event TokensRetrieved(address token, address to, uint256 amount);

    /**
     * @dev Sets the token name to "Lambro" and symbol to "LAMBRO". Initializes cap to MAX_SUPPLY.
     */
    constructor()
        ERC20("Lambro", "LAMBRO")
        ERC20Capped(MAX_SUPPLY)
        Ownable(msg.sender)
    {}


    /**
     * @notice Mints tokens to a specified address.
     * @dev Mints `amount` tokens to address `to`, ensuring the cap is not exceeded. Can only be called by the owner.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap(), "Lambro: cap exceeded");
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }

    /**
     * @notice Pauses all token transfers.
     * @dev Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
        emit TokenPaused(_msgSender());
    }

    /**
     * @notice Unpauses all token transfers.
     * @dev Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit TokenUnpaused(_msgSender());
    }

    /**
     * @dev Internal function to ensure token transfers are paused when necessary. Overrides ERC20 and ERC20Capped.
     * @param from The sender of the tokens.
     * @param to The recipient of the tokens.
     * @param amount The amount of tokens being transferred.
     */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
        whenNotPaused
    {
        super._update(from, to, amount);
    }

    /**
     * @notice Allows the owner to retrieve ERC20 tokens sent to this contract by mistake.
     * @dev This function allows for the recovery of any ERC20 tokens sent to the contract.
     * @param tokenAddress The address of the ERC20 token to retrieve.
     * @param to The address to which the tokens will be sent.
     * @param amount The amount of tokens to retrieve.
     */
    function retrieveTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Lambro: retrieve from zero address");
        require(to != address(0), "Lambro: transfer to zero address");
        require(amount > 0, "Lambro: amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(to, amount);
        emit TokensRetrieved(tokenAddress, to, amount);
    }

}