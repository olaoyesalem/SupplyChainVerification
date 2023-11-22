# SupplyChainVerification Smart Contract

## Overview

The SupplyChainVerification smart contract is designed for decentralized supply chain verification using Proof of Identity. This contract allows producers to add products to the supply chain, and verifiers to verify these products at various steps. The contract ensures transparency, traceability, and accountability in the supply chain process.

## Features

1. **Multi-Step Verification:** Products can go through multiple verification steps in the supply chain.

2. **Reward Mechanism:** Verifiers are rewarded for each verification, and the contract tracks the total reward for each product.

3. **Role-Based Access Control:** The contract defines roles for producers and verifiers, ensuring that only authorized entities can perform specific actions.

4. **Traceability:** Events are emitted for product additions and verifications, providing a transparent log of the entire supply chain process.

## Roles

- **Producer Role (PRODUCER_ROLE):** Allows adding products to the supply chain.

- **Verifier Role (VERIFIER_ROLE):** Allows verifying products in the supply chain.

- **Admin Role (DEFAULT_ADMIN_ROLE):** Allows managing roles and updating the Proof of Identity contract address.

## Getting Started

### Prerequisites

- [Truffle](https://www.trufflesuite.com/truffle)
- [Ganache](https://www.trufflesuite.com/ganache) or any Ethereum-compatible development blockchain
- [Node.js](https://nodejs.org/)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/supply-chain-verification.git
   ```
