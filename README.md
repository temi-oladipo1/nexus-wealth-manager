# Nexus Wealth Manager 🚀

[![Clarity Version](https://img.shields.io/badge/Clarity-3.0-blue)](https://clarity-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/Tests-Vitest-green)](https://vitest.dev/)
[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-orange)](https://stacks.co/)

> **Next-generation autonomous wealth orchestration platform for DeFi**

Nexus Wealth Manager revolutionizes decentralized finance through intelligent portfolio automation and dynamic asset management. This cutting-edge protocol empowers users to create sophisticated investment strategies with institutional-grade portfolio theory combined with blockchain innovation.

## 🌟 Key Features

- **🤖 Autonomous Multi-Asset Portfolio Orchestration** - Intelligent portfolio management across up to 10 digital assets
- **🧠 AI-Driven Rebalancing Algorithms** - Customizable triggers with automated portfolio optimization
- **⚡ Precision Allocation Engine** - Granular percentage-based asset allocation with basis point accuracy
- **🛡️ Enterprise-Grade Security Architecture** - Comprehensive safeguards and access controls
- **💰 Layer-2 Optimized Execution** - Minimal transaction costs with efficient smart contract design
- **📊 Real-Time Portfolio Analytics** - Performance monitoring and portfolio health tracking

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Smart Contract Structure](#smart-contract-structure)
- [Getting Started](#getting-started)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## 🏗️ Architecture Overview

The Nexus Wealth Manager is built on the Stacks blockchain using Clarity smart contracts. The protocol follows a modular architecture with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│           Nexus Wealth Manager          │
├─────────────────────────────────────────┤
│  👤 User Interface Layer                │
│  ├── Portfolio Creation                 │
│  ├── Asset Allocation Management        │
│  └── Rebalancing Controls               │
├─────────────────────────────────────────┤
│  🧮 Core Protocol Logic                 │
│  ├── Portfolio Registry                 │
│  ├── Asset Allocation Engine            │
│  ├── Rebalancing Algorithm              │
│  └── Access Control System              │
├─────────────────────────────────────────┤
│  💾 Data Storage Layer                  │
│  ├── Portfolio Mappings                 │
│  ├── Asset Allocation Data              │
│  └── User Portfolio Tracking            │
└─────────────────────────────────────────┘
```

## 📦 Smart Contract Structure

### Core Data Structures

#### Portfolio Registry

```clarity
(define-map Portfolios uint {
  owner: principal,
  created-at: uint,
  last-rebalanced: uint,
  total-value: uint,
  active: bool,
  token-count: uint
})
```

#### Asset Allocation Mapping

```clarity
(define-map PortfolioAssets 
  { portfolio-id: uint, token-id: uint }
  {
    target-percentage: uint,
    current-amount: uint,
    token-address: principal
  }
)
```

#### User Portfolio Tracking

```clarity
(define-map UserPortfolios principal (list 20 uint))
```

### Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX-TOKENS-PER-PORTFOLIO` | 10 | Maximum assets per portfolio |
| `BASIS-POINTS` | 10,000 | Percentage calculation precision |
| `PROTOCOL-FEE` | 25 | 0.25% protocol fee in basis points |

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 2.0
- [Node.js](https://nodejs.org/) >= 18
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ola-akanbi/nexus-wealth-manager.git
   cd nexus-wealth-manager
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify installation**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

## 📖 Usage Examples

### Creating a Portfolio

```typescript
// Create a balanced portfolio with 50% STX and 50% USDC allocation
const tokens = [
  'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.stackswap-token',
  'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.usdc-token'
];

const percentages = [5000, 5000]; // 50% each in basis points

const result = simnet.callPublicFn(
  'nexus-wealth',
  'create-portfolio',
  [Cl.list(tokens.map(t => Cl.principal(t))), Cl.list(percentages.map(p => Cl.uint(p)))],
  address1
);
```

### Rebalancing a Portfolio

```typescript
// Rebalance portfolio with ID 1
const result = simnet.callPublicFn(
  'nexus-wealth',
  'rebalance-portfolio',
  [Cl.uint(1)],
  portfolioOwner
);
```

### Updating Asset Allocation

```typescript
// Update token 0 allocation to 60% (6000 basis points)
const result = simnet.callPublicFn(
  'nexus-wealth',
  'update-portfolio-allocation',
  [Cl.uint(1), Cl.uint(0), Cl.uint(6000)],
  portfolioOwner
);
```

## 📚 API Reference

### Public Functions

#### `create-portfolio`

Creates a new portfolio with specified tokens and allocation percentages.

**Parameters:**

- `initial-tokens`: `(list 10 principal)` - List of token contract addresses
- `percentages`: `(list 10 uint)` - Allocation percentages in basis points

**Returns:** `(response uint uint)` - Portfolio ID on success

**Errors:**

- `ERR-MAX-TOKENS-EXCEEDED` (u107): Too many tokens specified
- `ERR-LENGTH-MISMATCH` (u108): Token and percentage lists length mismatch
- `ERR-INVALID-PERCENTAGE` (u106): Invalid percentage values

---

#### `rebalance-portfolio`

Executes rebalancing operation for the specified portfolio.

**Parameters:**

- `portfolio-id`: `uint` - Target portfolio identifier

**Returns:** `(response bool uint)` - Success status

**Errors:**

- `ERR-NOT-AUTHORIZED` (u100): Caller is not portfolio owner
- `ERR-INVALID-PORTFOLIO` (u101): Portfolio not found or inactive

---

#### `update-portfolio-allocation`

Modifies asset allocation percentage within existing portfolio.

**Parameters:**

- `portfolio-id`: `uint` - Portfolio identifier
- `token-id`: `uint` - Token position in portfolio
- `new-percentage`: `uint` - New allocation percentage in basis points

**Returns:** `(response bool uint)` - Success status

### Read-Only Functions

#### `get-portfolio`

Retrieves complete portfolio information.

**Parameters:**

- `portfolio-id`: `uint` - Portfolio identifier

**Returns:** `(optional portfolio-data)` - Portfolio details or none

---

#### `get-portfolio-asset`

Fetches specific asset allocation within a portfolio.

**Parameters:**

- `portfolio-id`: `uint` - Portfolio identifier
- `token-id`: `uint` - Token position

**Returns:** `(optional asset-data)` - Asset allocation details or none

---

#### `get-user-portfolios`

Returns all portfolios owned by a specific user.

**Parameters:**

- `user`: `principal` - User's principal address

**Returns:** `(list 20 uint)` - List of portfolio IDs

---

#### `calculate-rebalance-amounts`

Calculates rebalancing requirements and timing.

**Parameters:**

- `portfolio-id`: `uint` - Portfolio identifier

**Returns:** `(response rebalance-data uint)` - Rebalancing analysis

## 🧪 Testing

The project uses Vitest with Clarinet SDK for comprehensive testing.

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Structure

```
tests/
├── nexus-wealth.test.ts        # Main contract tests
├── portfolio-creation.test.ts  # Portfolio creation scenarios
├── rebalancing.test.ts         # Rebalancing functionality
└── edge-cases.test.ts          # Edge cases and error handling
```

### Writing Tests

```typescript
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

describe("Portfolio Creation", () => {
  it("creates portfolio with valid parameters", () => {
    const { result } = simnet.callPublicFn(
      "nexus-wealth",
      "create-portfolio",
      [
        Cl.list([Cl.principal(token1), Cl.principal(token2)]),
        Cl.list([Cl.uint(5000), Cl.uint(5000)])
      ],
      address1
    );
    expect(result).toBeOk(Cl.uint(1));
  });
});
```

## 🚢 Deployment

### Local Development

1. **Start Clarinet console**

   ```bash
   clarinet console
   ```

2. **Deploy contract**

   ```clarity
   ::deploy_contracts
   ```

3. **Interact with contract**

   ```clarity
   (contract-call? .nexus-wealth create-portfolio 
     (list 'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.token-a
           'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.token-b) 
     (list u5000 u5000))
   ```

### Testnet Deployment

1. **Configure network settings**

   ```bash
   # Edit settings/Testnet.toml
   clarinet integrate
   ```

2. **Deploy to testnet**

   ```bash
   clarinet deployment generate --testnet
   clarinet deployment apply --testnet
   ```

### Mainnet Deployment

1. **Security audit completion**
2. **Testnet validation**
3. **Configure mainnet settings**
4. **Execute deployment**

## 🤝 Contributing

We welcome contributions to the Nexus Wealth Manager! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make changes with tests**
4. **Commit with conventional commits**

   ```bash
   git commit -m "feat: add portfolio analytics dashboard"
   ```

5. **Push and create pull request**

### Code Standards

- **Clarity Code**: Follow [Clarity best practices](https://book.clarity-lang.org/)
- **TypeScript**: Use ESLint and Prettier configurations
- **Documentation**: Update README and inline comments
- **Testing**: Maintain >90% test coverage

### Commit Convention

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation updates
- `test:` Test improvements
- `refactor:` Code refactoring
- `style:` Formatting changes

## 🔒 Security

### Security Features

- **Access Control**: Owner-only portfolio management
- **Input Validation**: Comprehensive parameter validation
- **Overflow Protection**: Safe arithmetic operations
- **State Consistency**: Atomic transaction execution

### Security Considerations

- **Smart Contract Audits**: Regular security audits recommended
- **Permission Management**: Verify portfolio ownership before operations
- **Error Handling**: Graceful failure modes with descriptive errors
- **Rate Limiting**: Built-in rebalancing cooldowns

### Reporting Security Issues

Please report security vulnerabilities to: <security@nexus-wealth.com>

**Do not** create public issues for security vulnerabilities.

## 📜 Error Codes Reference

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-NOT-AUTHORIZED` | Unauthorized access attempt |
| 101 | `ERR-INVALID-PORTFOLIO` | Portfolio not found or invalid |
| 102 | `ERR-INSUFFICIENT-BALANCE` | Insufficient token balance |
| 103 | `ERR-INVALID-TOKEN` | Invalid token address |
| 104 | `ERR-REBALANCE-FAILED` | Rebalancing operation failed |
| 105 | `ERR-PORTFOLIO-EXISTS` | Portfolio already exists |
| 106 | `ERR-INVALID-PERCENTAGE` | Invalid percentage value |
| 107 | `ERR-MAX-TOKENS-EXCEEDED` | Too many tokens in portfolio |
| 108 | `ERR-LENGTH-MISMATCH` | Array length mismatch |
| 109 | `ERR-USER-STORAGE-FAILED` | User storage operation failed |
| 110 | `ERR-INVALID-TOKEN-ID` | Invalid token identifier |

## 🛣️ Roadmap

### Phase 1: Core Protocol ✅

- [x] Portfolio creation and management
- [x] Asset allocation engine
- [x] Basic rebalancing functionality
- [x] Security framework

### Phase 2: Advanced Features 🚧

- [ ] Automated rebalancing triggers
- [ ] Portfolio performance analytics
- [ ] Fee optimization strategies
- [ ] Cross-chain asset support

### Phase 3: Ecosystem Integration 📋

- [ ] DEX integration for automated trading
- [ ] Yield farming strategies
- [ ] Governance token integration
- [ ] Mobile application

### Phase 4: Enterprise Features 📋

- [ ] Institutional portfolio management
- [ ] Advanced risk management
- [ ] Regulatory compliance tools
- [ ] API gateway for third-party integrations
