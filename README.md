# Foundry Deployer Template

A minimal, ready-to-use template for Foundry smart contract projects that leverages the [foundry-deployer](https://github.com/EthSign/foundry-deployer) package for deterministic CREATE3 deployments.

## Features

- **Deterministic Addresses**: Deploy contracts to the same address across all EVM chains using CREATE3
- **Version Tracking**: Automatic deployment artifact tracking with version management
- **Gas Optimized**: Uses Solady for minimal gas overhead
- **Production Ready**: Includes ownership management and initialization patterns
- **CI/CD Ready**: Pre-configured GitHub Actions workflows

## Quick Start

### 1. Clone this template

```bash
git clone https://github.com/EthSign/foundry-deployer-template.git my-project
cd my-project
```

### 2. Install dependencies

```bash
forge install
```

### 3. Configure environment

```bash
cp .env.example .env
# Edit .env with your private key and RPC URLs
```

### 4. Build and test

```bash
forge build
forge test
```

### 5. Deploy

```bash
# Dry run (simulation)
forge script script/Deploy.s.sol --fork-url $SEPOLIA_RPC_URL

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Deploy to mainnet
forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast
```

## Project Structure

```
foundry-deployer-template/
├── src/
│   └── ExampleContract.sol       # Example versioned contract
├── script/
│   └── Deploy.s.sol              # Example deployment script
├── test/
│   └── ExampleContract.t.sol     # Example tests
├── deployments/                  # Deployment artifacts (auto-generated)
├── lib/                          # Dependencies (git submodules)
├── foundry.toml                  # Foundry configuration
├── .env.example                  # Environment template
└── README.md                     # This file
```

## Customizing for Your Project

### 1. Replace the example contract

Delete `src/ExampleContract.sol` and add your own contracts. Make sure they implement `IVersionable`:

```solidity
import {IVersionable} from "foundry-deployer/interfaces/IVersionable.sol";

contract MyContract is IVersionable {
    function version() external pure override returns (string memory) {
        return "1.0.0-MyContract"; // Format: {major}.{minor}.{patch}-{ContractName}
    }
}
```

### 2. Update the deployment script

Modify `script/Deploy.s.sol` to deploy your contracts:

```solidity
contract Deploy is DeployHelper {
    string constant CATEGORY = "my-project";

    function run() external {
        setup(CATEGORY);

        MyContract myContract = MyContract(
            deployContract({
                contractName: "MyContract",
                creationCode: type(MyContract).creationCode,
                initData: abi.encodeCall(MyContract.initialize, ()),
                value: 0
            })
        );
    }
}
```

### 3. Add tests

Create tests in the `test/` directory following the example in `ExampleContract.t.sol`.

## Environment Variables

### Required

- `PRIVATE_KEY`: Deployer private key
- `MAINNET_RPC_URL`: Mainnet RPC endpoint
- `SEPOLIA_RPC_URL`: Sepolia testnet RPC endpoint

### Optional

- `PROD_OWNER`: Address to transfer ownership to on mainnet (defaults to deployer)
- `MAINNET_CHAIN_IDS`: Comma-separated chain IDs considered "mainnet" (default: `1,56,137,8453`)
- `ALLOWED_DEPLOYMENT_SENDER`: Restrict deployments to specific address
- `FORCE_DEPLOY`: Set to `true` to force redeployment even if version exists

## Deployment Artifacts

Deployment information is automatically saved to `deployments/<category>/<chainId>/`:

- **Addresses**: `<ContractName>.json` - Deployed addresses by version
- **Verification**: `<ContractName>_verification.json` - Constructor args for Etherscan

## Key Concepts

### Deterministic Deployments (CREATE3)

The template uses CREATE3 to ensure your contracts deploy to the same address on all chains. The address depends only on:
- The deployer address
- The salt (derived from contract name)

### Version Management

Contracts implement `IVersionable` to enable version tracking:
- Each deployment is tracked by version
- Prevents accidental redeployments of the same version
- Allows multiple versions to coexist

### Ownership Transfer

On mainnet chains, ownership is automatically transferred to `PROD_OWNER` after deployment if configured.

## Advanced Usage

### Custom Salt Generation

Override `getSalt()` in your deployment script:

```solidity
function getSalt(string memory contractName) internal view virtual override returns (bytes32) {
    return keccak256(abi.encodePacked("my-prefix", contractName));
}
```

### Multi-Contract Deployments

Deploy multiple contracts in a single script:

```solidity
function run() external {
    setup("my-project");

    ContractA a = ContractA(deployContract({...}));
    ContractB b = ContractB(deployContract({...}));

    // Configure contracts to work together
    a.setContractB(address(b));
}
```

### Upgrading Contracts

To deploy a new version:

1. Update the `version()` function in your contract
2. Run the deployment script again
3. The new version will be deployed alongside the old one

## Troubleshooting

### `forge script --broadcast` succeeds but contract has no code on Anvil

**Symptom**: Your deployment script succeeds in simulation and broadcast reports no errors, but `cast code <address> --rpc-url http://127.0.0.1:8545` returns `0x`.

**Cause**: `CreateXHelper._ensureCreateX()` uses `vm.etch` to place CreateX bytecode at the expected address. However, `vm.etch` is a Forge cheatcode that only takes effect during **simulation** — it does not modify the actual chain state. Since Anvil does not ship with CreateX pre-deployed, the broadcast transaction targets an address with no code and silently fails.

**Fix**: Pre-deploy CreateX on your Anvil instance before running the script:

```bash
# Fetch CreateX bytecode and inject it into Anvil
CREATEX_BYTECODE=$(cast code 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed --rpc-url https://eth.llamarpc.com)
cast rpc anvil_setCode 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed "$CREATEX_BYTECODE" --rpc-url http://127.0.0.1:8545
```

After this, `forge script --broadcast` will work as expected against Anvil.

## Resources

- [foundry-deployer Documentation](https://github.com/EthSign/foundry-deployer)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solady Documentation](https://github.com/Vectorized/solady)

## License

MIT
