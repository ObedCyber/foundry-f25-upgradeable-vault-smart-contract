# Foundry Upgradable Vault (UUPS Pattern Demo)

This project is a **demonstration-only** smart contract system that showcases how to implement upgradeable contracts using the **UUPS (Universal Upgradeable Proxy Standard)** pattern with the **Foundry** development framework and **OpenZeppelin's** upgradeable libraries.

## Phase 1: Basic Bank v1 (Initial Version)

### Smart Contract Features

- `deposit()` function → Allows users to deposit ETH or ERC20 tokens.
- `withdraw()` function → Enables users to withdraw their ETH or ERC20 tokens.
- Mapping to track user balances.

---

## Phase 2: Upgrade to Bank v2 (UUPS Upgrade)

### New Features to Add:

- **Interest Accrual**: Users earn a small percentage APY on their deposited amount.

### Upgrade Process:

1. Use OpenZeppelin's `UUPSUpgradeable` base contracts.

2. Deploy an initial implementation contract.
3. Deploy a new logic contract later and upgrade the proxy to use it.

## 📁 Project Structure

```bash
.
├── src/
│   ├── VaultV1.sol       # Initial implementation
│   ├── VaultV2.sol       # Upgraded implementation
│   └── TestToken.sol     # Test Token contract 
├── script/
│   ├── DeployVaultV1AndInitialize.s.sol         # Deploys and Initialize VaultV1 behind proxy
│   └── DeployAndUpgradeVaultV2.s.sol # Upgrades proxy to VaultV2
├── test/                 # Optional: unit tests for Vault logic
│   ├── TestToken.t.sol         # Test Script for TestToken
│   ├── VaultV1Test.t.sol       # Test for basic VaultV! functionalities 
│   └── VaultV2Test.t.sol    # Test upgrade of VaultV1 to V2 and it's new functionalities

````