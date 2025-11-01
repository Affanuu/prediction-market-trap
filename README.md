## Prediction Market Trap 💹🪤

This is a Drosera smart contract trap for detecting and preventing prediction market manipulation through real-time monitoring and automated re>

The trap mechanism monitors prediction markets for suspicious activities including:

- **Price Manipulation**: Detects abnormal price movements (>20% change)
- **Volume Spikes**: Identifies unusual trading volume increases (>5x)
- **Market Manipulation Patterns**: Recognizes coordinated manipulation attempts

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

### Installation

```bash
# Clone the repository
git clone https://github.com/Affanuu/prediction-market-trap.git
cd prediction-market-trap

# Install dependencies
forge install

# Build contracts
forge build

# Run tests (should see 8/8 passing)
forge test -vvv
```

### Step 1: Prepare Environment

```bash
# Set your private key (use a test wallet!)
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Verify you have testnet ETH
cast balance YOUR_WALLET_ADDRESS --rpc-url https://ethereum-hoodi-rpc.publicnode.com

# If balance is 0, get testnet ETH from faucet:
# Visit: https://faucet.hoodi.drosera.io/
```

### Step 2: Deploy contracts

```bash
forge script script/DeployPredictionMarketTrap.s.sol \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Step 3: Configure Drosera

Update `drosera.toml` with your deployed addresses:

```toml
ethereum_rpc = "https://ethereum-hoodi-rpc.publicnode.com"
drosera_rpc = "https://relay.hoodi.drosera.io"
eth_chain_id = 560048
drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"

[traps]
[traps.prediction_market_manipulation]
path = "out/PredictionMarketTrapDeployable.sol/PredictionMarketTrapDeployable.json"
response_contract = "0xE8a61b9229CCf35B5cA384226A12c060671C2b56"
response_function = "executeManipulationResponse(uint256,address,uint256,uint256,uint256)"
cooldown_period_blocks = 6
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 2
private_trap = true
whitelist = ["YOUR_WALLET_ADDRESS"]
address = "YOUR_TRAP_ADDRESS"
```

### Step 4: Test Drosera DryRun

```bash
drosera dryrun
```
### Step 5: Deploy Trap

```bash
DROSERA_PRIVATE_KEY=$PRIVATE_KEY drosera apply
```

### Step 6: Test Manipulation Detection

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
