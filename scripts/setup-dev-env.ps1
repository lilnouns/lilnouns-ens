# LilNouns ENS Development Environment Setup Script (Windows PowerShell)
# This script helps new developers set up their development environment on Windows

param(
    [switch]$SkipTests,
    [switch]$SkipBuild
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    White = "White"
}

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

# Check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check Node.js version
function Test-NodeVersion {
    if (Test-Command "node") {
        $nodeVersion = node --version
        $versionNumber = [int]($nodeVersion -replace "v(\d+)\..*", '$1')

        if ($versionNumber -eq 22) {
            Write-Success "Node.js v22.x detected: $nodeVersion"
            return $true
        }
        elseif ($versionNumber -eq 23) {
            Write-Error "Node.js v23.x detected. This version is incompatible with Hardhat!"
            Write-Info "Please install Node.js v22.x using nvm-windows or the official installer"
            return $false
        }
        else {
            Write-Warning "Node.js v$versionNumber detected. Recommended version is v22.x"
            Write-Info "Current version: $nodeVersion"
            return $false
        }
    }
    else {
        Write-Error "Node.js not found. Please install Node.js v22.x"
        return $false
    }
}

# Install Node.js using Chocolatey if available
function Install-Node {
    if (Test-Command "choco") {
        Write-Info "Installing Node.js v22 using Chocolatey..."
        try {
            choco install nodejs --version=22.0.0 -y
            Write-Success "Node.js v22 installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install Node.js using Chocolatey"
            return $false
        }
    }
    elseif (Test-Command "winget") {
        Write-Info "Installing Node.js using winget..."
        try {
            winget install OpenJS.NodeJS
            Write-Success "Node.js installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install Node.js using winget"
            return $false
        }
    }
    else {
        Write-Warning "Neither Chocolatey nor winget found. Please install Node.js v22.x manually"
        Write-Info "Visit: https://nodejs.org/ or install Chocolatey: https://chocolatey.org/"
        return $false
    }
}

# Check and install pnpm
function Set-Pnpm {
    if (Test-Command "pnpm") {
        $pnpmVersion = pnpm --version
        Write-Success "pnpm detected: v$pnpmVersion"
        return $true
    }
    else {
        Write-Info "Installing pnpm..."
        if (Test-Command "npm") {
            try {
                npm install -g pnpm
                Write-Success "pnpm installed successfully"
                return $true
            }
            catch {
                Write-Error "Failed to install pnpm using npm"
                return $false
            }
        }
        else {
            Write-Error "npm not found. Cannot install pnpm"
            return $false
        }
    }
}

# Check and install Foundry
function Set-Foundry {
    if (Test-Command "forge") {
        $forgeVersion = forge --version | Select-Object -First 1
        Write-Success "Foundry detected: $forgeVersion"
        return $true
    }
    else {
        Write-Info "Installing Foundry..."
        Write-Info "Foundry installation on Windows requires manual setup."
        Write-Info "Please follow these steps:"
        Write-Info "1. Install Git for Windows if not already installed"
        Write-Info "2. Open Git Bash or PowerShell"
        Write-Info "3. Run: curl -L https://foundry.paradigm.xyz | bash"
        Write-Info "4. Follow the installation instructions"
        Write-Info "5. Add Foundry to your PATH environment variable"
        Write-Warning "Please install Foundry manually and re-run this script"
        return $false
    }
}

# Setup environment files
function Set-EnvironmentFiles {
    Write-Info "Setting up environment configuration files..."

    # Create .env.example if it doesn't exist
    if (-not (Test-Path ".env.example")) {
        $envExample = @"
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
"@
        $envExample | Out-File -FilePath ".env.example" -Encoding UTF8
        Write-Success "Created .env.example file"
    }

    # Create .env file if it doesn't exist
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Success "Created .env file from template"
        Write-Warning "Please update .env file with your actual API keys and configuration"
    }
    else {
        Write-Info ".env file already exists"
    }

    # Create contracts .env.example if it doesn't exist
    if (-not (Test-Path "packages/contracts/.env.example")) {
        Copy-Item ".env.example" "packages/contracts/.env.example"
        Write-Success "Created packages/contracts/.env.example file"
    }

    # Create contracts .env file if it doesn't exist
    if (-not (Test-Path "packages/contracts/.env")) {
        Copy-Item ".env.example" "packages/contracts/.env"
        Write-Success "Created packages/contracts/.env file from template"
    }
}

# Install dependencies
function Install-Dependencies {
    Write-Info "Installing project dependencies..."

    if (Test-Command "pnpm") {
        try {
            pnpm install
            Write-Success "Dependencies installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install dependencies"
            return $false
        }
    }
    else {
        Write-Error "pnpm not found. Cannot install dependencies"
        return $false
    }
}

# Build the project
function Build-Project {
    if ($SkipBuild) {
        Write-Info "Skipping build as requested"
        return $true
    }

    Write-Info "Building the project..."

    # Build contracts first
    Write-Info "Building contracts..."
    try {
        Set-Location "packages/contracts"
        pnpm run build:forge
        pnpm run build:hardhat
        Set-Location "../.."
        Write-Success "Contracts built successfully"
    }
    catch {
        Write-Warning "Contract build failed, but continuing..."
        Set-Location "../.."
    }

    # Try to build the web app if it exists
    if (Test-Path "apps/web") {
        Write-Info "Building web app..."
        try {
            Set-Location "apps/web"
            pnpm run build
            Write-Success "Web app built successfully"
            Set-Location "../.."
        }
        catch {
            Write-Warning "Web app build failed, but continuing..."
            Set-Location "../.."
        }
    }

    return $true
}

# Run tests
function Invoke-Tests {
    if ($SkipTests) {
        Write-Info "Skipping tests as requested"
        return $true
    }

    Write-Info "Running tests to verify setup..."

    try {
        Set-Location "packages/contracts"

        try {
            pnpm run test:forge
            Write-Success "Forge tests passed"
        }
        catch {
            Write-Warning "Forge tests failed, but setup continues..."
        }

        try {
            pnpm run test:hardhat
            Write-Success "Hardhat tests passed"
        }
        catch {
            Write-Warning "Hardhat tests failed, but setup continues..."
        }

        Set-Location "../.."
    }
    catch {
        Write-Warning "Failed to run tests, but setup continues..."
        Set-Location "../.."
    }

    return $true
}

# Verify installation
function Test-Installation {
    Write-Info "Verifying installation..."

    $allGood = $true

    if (-not (Test-NodeVersion)) {
        $allGood = $false
    }

    if (-not (Test-Command "pnpm")) {
        Write-Error "pnpm not found"
        $allGood = $false
    }

    if (-not (Test-Command "forge")) {
        Write-Error "Foundry (forge) not found"
        $allGood = $false
    }

    if ($allGood) {
        Write-Success "All tools are properly installed!"
        return $true
    }
    else {
        Write-Error "Some tools are missing or incorrectly configured"
        return $false
    }
}

# Print next steps
function Write-NextSteps {
    Write-Host ""
    Write-Info "🎉 Development environment setup complete!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Update your .env file with actual API keys and configuration"
    Write-Host "2. Review the README.md for detailed usage instructions"
    Write-Host "3. Start developing with: pnpm dev"
    Write-Host ""
    Write-Host "Useful commands:"
    Write-Host "  pnpm build          - Build all packages"
    Write-Host "  pnpm test           - Run all tests"
    Write-Host "  pnpm lint           - Run linting"
    Write-Host "  pnpm format         - Format code"
    Write-Host ""
    Write-Host "For contracts specifically:"
    Write-Host "  cd packages/contracts"
    Write-Host "  pnpm test:forge     - Run Forge tests"
    Write-Host "  pnpm test:hardhat   - Run Hardhat tests"
    Write-Host "  pnpm deploy:sepolia - Deploy to Sepolia testnet"
    Write-Host ""
}

# Main setup function
function Main {
    Write-Host ""
    Write-Info "🚀 LilNouns ENS Development Environment Setup (Windows)"
    Write-Host ""

    # Check and setup Node.js
    if (-not (Test-NodeVersion)) {
        if (-not (Install-Node)) {
            Write-Error "Failed to install Node.js. Please install manually and re-run this script."
            exit 1
        }
    }

    # Setup pnpm
    if (-not (Set-Pnpm)) {
        Write-Error "Failed to setup pnpm"
        exit 1
    }

    # Setup Foundry
    if (-not (Set-Foundry)) {
        Write-Error "Failed to setup Foundry. Please install manually and re-run this script."
        exit 1
    }

    # Setup environment files
    Set-EnvironmentFiles

    # Install dependencies
    if (-not (Install-Dependencies)) {
        Write-Error "Failed to install dependencies"
        exit 1
    }

    # Build project
    if (-not (Build-Project)) {
        Write-Warning "Build failed, but setup continues..."
    }

    # Run tests
    Invoke-Tests

    # Verify installation
    Test-Installation

    # Print next steps
    Write-NextSteps
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
