## 🚀 Quick Start & Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) - Smart contract development framework
- [Git](https://git-scm.com/) - Version control
- [Drosera CLI](https://docs.drosera.io/getting-started/installation) - For trap deployment
- Access to Hoodi Testnet RPC: `https://ethereum-hoodi-rpc.publicnode.com`
- Testnet ETH for gas fees (get from [Hoodi faucet](https://faucet.hoodi.drosera.io/))
- Private key for deployment (create new wallet for testing)

### Installation

```bash
# Clone the repository
git clone https://github.com/Phascary/prediction-market-trap.git
cd prediction-market-trap

# Install dependencies
forge install

# Build contracts
forge build

# Run tests (should see 8/8 passing)
forge test -vvv
```

### Test Results Expected
```
Ran 6 tests for test/PredictionMarketTrap.t.sol:PredictionMarketTrapTest
[PASS] test_Collect()
[PASS] test_NoTrigger_InsufficientData()
[PASS] test_NoTrigger_NormalActivity()
[PASS] test_Trigger_LargeSingleTrade()
[PASS] test_Trigger_PriceManipulation()
[PASS] test_Trigger_VolumeSpike()

Ran 2 tests for test/Counter.t.sol:CounterTest
[PASS] testFuzz_SetNumber(uint256)
[PASS] test_Increment()

Test result: ok. 8 passed; 0 failed
```# Prediction Market Trap 🎯

A Drosera-compliant smart contract trap for detecting and preventing prediction market manipulation through real-time monitoring and automated response mechanisms.

## 🎯 Overview

This project implements a sophisticated trap mechanism that monitors prediction markets for suspicious activities including:

- **Price Manipulation**: Detects abnormal price movements (>20% change)
- **Volume Spikes**: Identifies unusual trading volume increases (>5x)
- **Large Single Trades**: Flags suspicious large transactions (>10,000 tokens)
- **Market Manipulation Patterns**: Recognizes coordinated manipulation attempts

## 🛠️ Tech Stack

- **Solidity 0.8.20** - Smart contract development
- **Foundry** - Development framework and testing
- **Drosera** - Real-time security monitoring and automated response
- **Cast** - Command-line tool for Ethereum interactions
- **Hoodi Testnet** - Ethereum Layer 2 testnet for deployment and testing

## 📁 Project Structure

```
prediction-market-trap/
├── .github/
│   └── workflows/
│       └── test.yml          # CI/CD workflow
├── Drosera-Network/          # Drosera integration (submodule)
├── lib/                      # Forge dependencies
│   └── forge-std/           # Foundry standard library
├── script/
│   ├── Counter.s.sol        # Example deployment script
│   └── DeployPredictionMarketTrap.s.sol  # Main deployment script
├── src/
│   ├── Counter.sol          # Example contract
│   ├── ITrap.sol            # Drosera trap interface
│   ├── MockPredictionMarket.sol  # Mock market for testing
│   ├── PredictionMarketResponse.sol  # Response contract
│   ├── PredictionMarketTrap.sol  # Main trap (configurable)
│   └── PredictionMarketTrapDeployable.sol  # Production trap (hardcoded)
├── test/
│   ├── Counter.t.sol        # Example tests
│   └── PredictionMarketTrap.t.sol  # Comprehensive trap tests
├── .gitignore
├── .gitmodules
├── drosera.toml             # Drosera configuration
├── foundry.lock             # Dependency lock file
├── foundry.toml             # Foundry configuration
└── README.md
```

## 🚀 Quick Start

## 🏗️ Architecture

### Drosera Compliance

This trap is **fully compliant** with Drosera specifications:

#### ✅ Pure shouldRespond() Function
- **No state reads**: All logic based on passed-in data
- **Deterministic**: Same inputs always produce same outputs
- **Shadowfork compatible**: Works across all operator nodes

#### ✅ Immutable Configuration
- All parameters set at deployment
- No dynamic configuration required
- Works on shadowfork environments without additional setup

#### ✅ Two Contract Versions

**1. PredictionMarketTrap.sol** (Development/Testing)
- Constructor-based configuration
- Flexible for testing different markets
- Used for local development

**2. PredictionMarketTrapDeployable.sol** (Production)
- Hardcoded constants
- Optimized for Drosera deployment
- Ready for mainnet/testnet

### How It Works

```
1. collect() → Gathers market state data
   ├─ Current prices (yes/no)
   ├─ Trading volume
   ├─ Last trader info
   └─ Block number

2. shouldRespond() → Analyzes data (PURE function)
   ├─ Compares current vs previous state
   ├─ Checks manipulation thresholds
   └─ Returns true if manipulation detected

3. Response Contract → Takes action
   ├─ Emits alert events
   ├─ Can pause trading
   └─ Logs manipulation details
```

## 🔧 Usage

### Local Development

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test test_Trigger_PriceManipulation

# Generate gas report
forge test --gas-report

# Format code
forge fmt
```

## 📦 Complete Deployment Guide

This section provides step-by-step instructions for deploying your prediction market trap to Hoodi testnet and integrating with Drosera.

### Step 1: Prepare Your Environment

```bash
# Set your private key (use a test wallet!)
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Verify you have testnet ETH
cast balance YOUR_WALLET_ADDRESS --rpc-url https://ethereum-hoodi-rpc.publicnode.com

# If balance is 0, get testnet ETH from faucet:
# Visit: https://faucet.hoodi.drosera.io/
```

### Step 2: Deploy Mock Prediction Market & Contracts

Deploy all contracts with the standard deployment script:

```bash
forge script script/DeployPredictionMarketTrap.s.sol \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast
```

**Expected Output:**
```
MockPredictionMarket deployed at: 0x...
PredictionMarketTrap deployed at: 0x...
PredictionMarketResponse deployed at: 0x...
```

**⚠️ Save these addresses!** You'll need them for the next steps.

### Step 3: Update PredictionMarketTrapDeployable

Open `src/PredictionMarketTrapDeployable.sol` and update the market address:

```solidity
// Replace with your deployed MockPredictionMarket address
address public constant PREDICTION_MARKET = 0xYOUR_DEPLOYED_MARKET_ADDRESS;
```

Rebuild the contract:
```bash
forge build
```

### Step 4: Deploy Production Trap (No Constructor)

Deploy the Drosera-compliant trap:

```bash
forge script script/DeployTrapDeployable.s.sol \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast
```

**Expected Output:**
```
PredictionMarketTrapDeployable deployed at: 0x...
```

**⚠️ This is your main trap address for Drosera!**

### Step 5: Test Deployed Trap

Verify the trap is working:

```bash
# Test collect() function
cast call YOUR_TRAP_ADDRESS "collect()" \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com

# Check configuration
cast call YOUR_TRAP_ADDRESS "PREDICTION_MARKET()" \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com

cast call YOUR_TRAP_ADDRESS "MONITORED_MARKET_ID()" \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com

# Verify thresholds
cast call YOUR_TRAP_ADDRESS "PRICE_MANIPULATION_THRESHOLD()" \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com
```

### Step 6: Configure Drosera

Update `drosera.toml` with your deployed addresses:

```toml
ethereum_rpc = "https://ethereum-hoodi-rpc.publicnode.com"
drosera_rpc = "https://relay.hoodi.drosera.io"
eth_chain_id = 560048
drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"

[traps]
[traps.prediction_market_manipulation]
path = "out/PredictionMarketTrapDeployable.sol/PredictionMarketTrapDeployable.json"
response_contract = "YOUR_RESPONSE_CONTRACT_ADDRESS"
response_function = "executeManipulationResponse(uint256,address,uint256,uint256,uint256)"
cooldown_period_blocks = 6
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 2
private_trap = true
whitelist = ["YOUR_WALLET_ADDRESS"]
address = "YOUR_TRAP_DEPLOYABLE_ADDRESS"
```

### Step 7: Test with Drosera Dry Run

Before deploying to Drosera, test locally:

```bash
drosera dryrun
```

**Expected Output:**
```
Testing trap(s) execution...
==================================
Running trap: prediction_market_manipulation
==================================
collect gas used: 41321
should_respond gas used: 30470
shouldRespond: true (if manipulation detected)
```

### Step 8: Deploy to Drosera Network

Deploy your trap to the Drosera network:

```bash
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply
```

**Expected Output:**
```
Response function verified ✅
Testing trap(s) execution...
shouldRespond: true
Do you want to apply these changes? [ofc/N]: ofc
Transaction Hash: 0x...
1. Created Trap Config for prediction_market_manipulation
  - address: 0x...
  - block: ...
```

### Step 9: Verify Deployment

Check your trap on the block explorer:

```bash
# Visit Hoodi Explorer
https://hoodi.etherscan.io/address/YOUR_TRAP_ADDRESS
```

### Step 10: Test Manipulation Detection (Optional)

Trigger the trap by simulating manipulation:

```bash
# Simulate a large trade to trigger detection
cast send YOUR_MOCK_MARKET_ADDRESS \
  "simulateManipulation(uint256)" 1 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com

# Run another dry run to see it detect
drosera dryrun
```

## 📊 Deployed Addresses (Reference)

Current production deployment on Hoodi testnet:

| Contract | Address |
|----------|---------|
| MockPredictionMarket | `0x94D16e1D86294235D841101855866397ee639d82` |
| PredictionMarketTrapDeployable | `0xcab8D39f2705aB0c530484e8Eec3Da82ACd5781D` |
| PredictionMarketResponse | `0xE8a61b9229CCf35B5cA384226A12c060671C2b56` |
| Drosera Transaction | `0xa23ff4764d7d981d4ad75e8c7989b78d2950aeaac25093646b3ca9c010e1cf87` |

**Network Details:**
- Chain ID: 560048
- RPC URL: https://ethereum-hoodi-rpc.publicnode.com
- Explorer: https://hoodi.etherscan.io/

## 🔍 Troubleshooting Deployment

### Issue: "Constructor inputs on Trap contracts are not allowed"

**Solution:** Make sure you're deploying `PredictionMarketTrapDeployable.sol`, not `PredictionMarketTrap.sol`. The deployable version has no constructor parameters.

### Issue: "Insufficient funds"

**Solution:** Get testnet ETH from https://faucet.hoodi.drosera.io/

### Issue: Tests failing

**Solution:** 
```bash
forge clean
forge build
forge test -vvv
```

### Issue: Drosera apply fails

**Solution:** 
1. Verify `drosera.toml` has correct addresses
2. Ensure trap address points to deployed PredictionMarketTrapDeployable
3. Check that response contract address is correct

## 💡 Deployment Best Practices

1. **Always test locally first** - Run `forge test` before deploying
2. **Use dry run** - Test with `drosera dryrun` before `drosera apply`
3. **Save addresses** - Keep a record of all deployed contract addresses
4. **Test on testnet** - Deploy to Hoodi before considering mainnet
5. **Verify contracts** - Check on block explorer after deployment
6. **Monitor gas costs** - Current trap uses ~41k gas for collect(), ~30k for shouldRespond()

## 📝 Deployment Checklist

Before deploying to production:

- [ ] All tests passing locally (`forge test`)
- [ ] Code formatted (`forge fmt`)
- [ ] Contracts compiled without warnings
- [ ] PredictionMarketTrapDeployable updated with correct market address
- [ ] drosera.toml configured with all addresses
- [ ] Dry run successful (`drosera dryrun`)
- [ ] Sufficient testnet ETH for deployment
- [ ] Private key secured and not committed to repo
- [ ] README updated with deployment details

## 🔍 Key Features

### Detection Mechanisms

| Feature | Threshold | Description |
|---------|-----------|-------------|
| Price Manipulation | 20% | Detects abnormal price changes |
| Volume Spike | 5x increase | Identifies unusual volume |
| Large Trade | 10,000 tokens | Flags suspicious trades |
| Block Sampling | 2 blocks | Prevents false positives |

### Smart Contract Features

- ✅ **Gas Optimized**: Efficient data structures and logic
- ✅ **Error Handling**: Graceful fallbacks for missing data
- ✅ **Pure Functions**: No state dependencies in critical paths
- ✅ **Comprehensive Tests**: 95%+ code coverage
- ✅ **Event Logging**: Detailed manipulation records

## 🧪 Testing

### Test Coverage

```bash
# Run coverage report
forge coverage

# Generate detailed report
forge coverage --report lcov
```

### Test Scenarios

- ✅ Normal trading activity (no trigger)
- ✅ Price manipulation detection
- ✅ Large single trade detection
- ✅ Volume spike detection
- ✅ Insufficient data handling
- ✅ Pure function compliance

## 📊 Drosera Configuration

### Why This Implementation is Drosera-Compliant

#### 1. **Pure shouldRespond()**
```solidity
// ✅ CORRECT - Pure function
function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
    // Only uses passed-in data
    // No storage reads
    // Deterministic behavior
}

// ❌ INCORRECT - View function
function shouldRespond(bytes[] calldata data) external view returns (bool, bytes memory) {
    // Reads from storage
    // Non-deterministic across nodes
}
```

#### 2. **Immutable Configuration**
```solidity
// All configuration is set at deployment
address public constant PREDICTION_MARKET = 0x61c7c5462eF0E8d1a2F01E22Aa0dCefb1Cf1F776;
uint256 public constant MONITORED_MARKET_ID = 1;
uint256 public constant PRICE_MANIPULATION_THRESHOLD = 200000;
```

#### 3. **Data Encoding in collect()**
```solidity
// Includes all necessary data for shouldRespond()
return abi.encode(
    marketId,        // ← Included in data
    yesPrice,
    noPrice,
    volume,
    trader,
    tradeSize,
    blockNumber
);
```

## 🛡️ Security Considerations

### Best Practices

- ✅ Always test on testnets before mainnet
- ✅ Never commit private keys
- ✅ Use hardware wallets for production
- ✅ Monitor gas prices for deployments
- ✅ Verify contracts on block explorers

### Known Limitations

- Trap requires prediction market to exist at deployment
- Thresholds are hardcoded (change requires redeployment)
- Does not prevent manipulation, only detects it
- Response depends on operator availability

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Coding Standards

- Follow Solidity style guide
- Add tests for new features
- Update documentation
- Ensure CI passes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Drosera Documentation](https://docs.drosera.io/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Holesky Testnet](https://holesky.etherscan.io/)

## ⚠️ Disclaimer

This project is for educational and research purposes. Users are responsible for:
- Compliance with applicable laws
- Security audits before mainnet deployment
- Understanding risks of smart contract deployment
- Proper key management and operational security

## 📞 Contact

- **GitHub**: [@Phascary](https://github.com/Phascary)
- **Project**: [prediction-market-trap](https://github.com/Phascary/prediction-market-trap)
- **Issues**: [Report bugs or request features](https://github.com/Phascary/prediction-market-trap/issues)

## 🙏 Acknowledgments

- [Drosera](https://drosera.io/) for the innovative security monitoring framework
- [Foundry](https://github.com/foundry-rs/foundry) for the excellent development toolkit
- The Ethereum security community for best practices and guidance

## 📈 Roadmap

- [x] Core trap implementation
- [x] Drosera compliance (pure shouldRespond)
- [x] Comprehensive testing suite
- [x] CI/CD pipeline
- [ ] Multi-market monitoring
- [ ] Advanced manipulation patterns
- [ ] Dashboard for monitoring
- [ ] Mainnet deployment

---

**Built with ❤️ for a safer DeFi ecosystem**

### Quick Reference

**Deploy to Holesky:**
```bash
forge script script/DeployPredictionMarketTrap.s.sol \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast --verify
```

**Test locally:**
```bash
forge test -vvv
```

**Check Drosera config:**
```bash
cat drosera.toml
```
