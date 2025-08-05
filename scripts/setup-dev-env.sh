#!/bin/bash

# LilNouns ENS Development Environment Setup Script
# This script helps new developers set up their development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js version
check_node_version() {
    if command_exists node; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -eq 22 ]; then
            log_success "Node.js v22.x detected: $(node --version)"
            return 0
        elif [ "$NODE_VERSION" -eq 23 ]; then
            log_error "Node.js v23.x detected. This version is incompatible with Hardhat!"
            log_info "Please install Node.js v22.x using nvm or your preferred Node.js version manager"
            return 1
        else
            log_warning "Node.js v$NODE_VERSION detected. Recommended version is v22.x"
            log_info "Current version: $(node --version)"
            return 1
        fi
    else
        log_error "Node.js not found. Please install Node.js v22.x"
        return 1
    fi
}

# Install Node.js using nvm if available
install_node() {
    if command_exists nvm; then
        log_info "Installing Node.js v22 using nvm..."
        nvm install 22
        nvm use 22
        nvm alias default 22
        log_success "Node.js v22 installed and set as default"
    else
        log_warning "nvm not found. Please install Node.js v22.x manually"
        log_info "Visit: https://nodejs.org/ or install nvm: https://github.com/nvm-sh/nvm"
        return 1
    fi
}

# Check and install pnpm
setup_pnpm() {
    if command_exists pnpm; then
        PNPM_VERSION=$(pnpm --version)
        log_success "pnpm detected: v$PNPM_VERSION"
    else
        log_info "Installing pnpm..."
        if command_exists npm; then
            npm install -g pnpm
            log_success "pnpm installed successfully"
        else
            log_error "npm not found. Cannot install pnpm"
            return 1
        fi
    fi
}

# Check and install Foundry
setup_foundry() {
    if command_exists forge; then
        FORGE_VERSION=$(forge --version | head -n1)
        log_success "Foundry detected: $FORGE_VERSION"
    else
        log_info "Installing Foundry..."
        if command_exists curl; then
            curl -L https://foundry.paradigm.xyz | bash
            # Source the foundry env
            export PATH="$HOME/.foundry/bin:$PATH"
            if [ -f "$HOME/.bashrc" ]; then
                echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc"
            fi
            if [ -f "$HOME/.zshrc" ]; then
                echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.zshrc"
            fi
            foundryup
            log_success "Foundry installed successfully"
        else
            log_error "curl not found. Cannot install Foundry"
            log_info "Please install Foundry manually: https://getfoundry.sh/"
            return 1
        fi
    fi
}

# Setup environment files
setup_env_files() {
    log_info "Setting up environment configuration files..."

    # Create .env.example if it doesn't exist
    if [ ! -f ".env.example" ]; then
        cat > .env.example << 'EOF'
# Network RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/YOUR_ALCHEMY_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.alchemyapi.io/v2/YOUR_ALCHEMY_KEY
GOERLI_RPC_URL=https://eth-goerli.alchemyapi.io/v2/YOUR_ALCHEMY_KEY

# Private key for deployment (DO NOT COMMIT TO VERSION CONTROL)
PRIVATE_KEY=your_private_key_here

# Etherscan API key for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Gas reporting (set to true to enable)
REPORT_GAS=false

# Coinmarketcap API key for gas reporting (optional)
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key_here
EOF
        log_success "Created .env.example file"
    fi

    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_warning "Please update .env file with your actual API keys and configuration"
    else
        log_info ".env file already exists"
    fi

    # Create contracts .env.example if it doesn't exist
    if [ ! -f "packages/contracts/.env.example" ]; then
        cp .env.example packages/contracts/.env.example
        log_success "Created packages/contracts/.env.example file"
    fi

    # Create contracts .env file if it doesn't exist
    if [ ! -f "packages/contracts/.env" ]; then
        cp .env.example packages/contracts/.env
        log_success "Created packages/contracts/.env file from template"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing project dependencies..."

    if command_exists pnpm; then
        pnpm install
        log_success "Dependencies installed successfully"
    else
        log_error "pnpm not found. Cannot install dependencies"
        return 1
    fi
}

# Build the project
build_project() {
    log_info "Building the project..."

    # Build contracts first
    log_info "Building contracts..."
    cd packages/contracts
    pnpm build:forge
    pnpm build:hardhat
    cd ../..
    log_success "Contracts built successfully"

    # Try to build the web app if it exists
    if [ -d "apps/web" ]; then
        log_info "Building web app..."
        cd apps/web
        if pnpm build; then
            log_success "Web app built successfully"
        else
            log_warning "Web app build failed, but continuing..."
        fi
        cd ../..
    fi
}

# Run tests
run_tests() {
    log_info "Running tests to verify setup..."

    cd packages/contracts
    if pnpm test:forge; then
        log_success "Forge tests passed"
    else
        log_warning "Forge tests failed, but setup continues..."
    fi

    if pnpm test:hardhat; then
        log_success "Hardhat tests passed"
    else
        log_warning "Hardhat tests failed, but setup continues..."
    fi
    cd ../..
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    local all_good=true

    if ! check_node_version; then
        all_good=false
    fi

    if ! command_exists pnpm; then
        log_error "pnpm not found"
        all_good=false
    fi

    if ! command_exists forge; then
        log_error "Foundry (forge) not found"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        log_success "All tools are properly installed!"
        return 0
    else
        log_error "Some tools are missing or incorrectly configured"
        return 1
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    log_info "🎉 Development environment setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Update your .env file with actual API keys and configuration"
    echo "2. Review the README.md for detailed usage instructions"
    echo "3. Start developing with: pnpm dev"
    echo ""
    echo "Useful commands:"
    echo "  pnpm build          - Build all packages"
    echo "  pnpm test           - Run all tests"
    echo "  pnpm lint           - Run linting"
    echo "  pnpm format         - Format code"
    echo ""
    echo "For contracts specifically:"
    echo "  cd packages/contracts"
    echo "  pnpm test:forge     - Run Forge tests"
    echo "  pnpm test:hardhat   - Run Hardhat tests"
    echo "  pnpm deploy:sepolia - Deploy to Sepolia testnet"
    echo ""
}

# Main setup function
main() {
    echo ""
    log_info "🚀 LilNouns ENS Development Environment Setup"
    echo ""

    # Check and setup Node.js
    if ! check_node_version; then
        if ! install_node; then
            log_error "Failed to install Node.js. Please install manually and re-run this script."
            exit 1
        fi
    fi

    # Setup pnpm
    if ! setup_pnpm; then
        log_error "Failed to setup pnpm"
        exit 1
    fi

    # Setup Foundry
    if ! setup_foundry; then
        log_error "Failed to setup Foundry"
        exit 1
    fi

    # Setup environment files
    setup_env_files

    # Install dependencies
    if ! install_dependencies; then
        log_error "Failed to install dependencies"
        exit 1
    fi

    # Build project
    if ! build_project; then
        log_warning "Build failed, but setup continues..."
    fi

    # Run tests
    run_tests

    # Verify installation
    verify_installation

    # Print next steps
    print_next_steps
}

# Run main function
main "$@"
