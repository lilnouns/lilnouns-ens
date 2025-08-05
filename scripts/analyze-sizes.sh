#!/bin/bash

# LilNouns ENS Build Size Analysis Script
# This script analyzes contract and web bundle sizes for optimization

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

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc -l)MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc -l)KB"
    else
        echo "${bytes}B"
    fi
}

# Function to analyze contract sizes
analyze_contracts() {
    log_info "Analyzing smart contract sizes..."

    if [ ! -d "packages/contracts" ]; then
        log_error "Contracts directory not found"
        return 1
    fi

    cd packages/contracts

    # Build contracts to get size information
    if ! pnpm build:forge >/dev/null 2>&1; then
        log_error "Failed to build contracts"
        cd ../..
        return 1
    fi

    echo ""
    echo "📊 Contract Size Analysis"
    echo "========================="
    printf "%-30s %-12s %-10s %-15s\n" "Contract" "Size (bytes)" "Size (KB)" "Status"
    echo "--------------------------------------------------------------------------------"

    local total_size=0
    local contract_count=0

    # Analyze contract sizes from Forge build output
    forge build --sizes 2>/dev/null | grep -E "\.sol:" | while read line; do
        contract=$(echo "$line" | awk '{print $1}' | sed 's/.*\///' | sed 's/\.sol://')
        size_bytes=$(echo "$line" | awk '{print $2}')
        size_kb=$(echo "scale=2; $size_bytes / 1024" | bc -l 2>/dev/null || echo "N/A")

        # Determine optimization status
        if [ "$size_bytes" -gt 24576 ]; then
            status="${RED}⚠️  Large (>24KB)${NC}"
        elif [ "$size_bytes" -gt 16384 ]; then
            status="${YELLOW}⚡ Medium (>16KB)${NC}"
        else
            status="${GREEN}✅ Optimal (<16KB)${NC}"
        fi

        printf "%-30s %-12s %-10s %-15s\n" "$contract" "$size_bytes" "$size_kb" "$status"

        total_size=$((total_size + size_bytes))
        contract_count=$((contract_count + 1))
    done

    echo "--------------------------------------------------------------------------------"
    echo "Total contracts: $contract_count"
    echo "Total size: $(format_bytes $total_size)"

    echo ""
    echo "🔧 Contract Optimization Recommendations:"
    echo "- Contracts >24KB may hit deployment limits on some networks"
    echo "- Consider using libraries for shared functionality"
    echo "- Remove unused imports and functions"
    echo "- Use custom errors instead of string messages"
    echo "- Consider proxy patterns for large contracts"

    cd ../..
}

# Function to analyze web bundle sizes
analyze_web_bundles() {
    log_info "Analyzing web application bundle sizes..."

    if [ ! -d "apps/web" ]; then
        log_warning "Web app directory not found, skipping bundle analysis"
        return 0
    fi

    cd apps/web

    # Build web app to get bundle information
    if ! pnpm build >/dev/null 2>&1; then
        log_error "Failed to build web application"
        cd ../..
        return 1
    fi

    echo ""
    echo "📦 Web Bundle Size Analysis"
    echo "==========================="
    printf "%-40s %-10s %-12s %-15s\n" "File" "Size" "Gzipped" "Status"
    echo "--------------------------------------------------------------------------------"

    local total_size=0
    local file_count=0

    # Analyze bundle sizes if dist directory exists
    if [ -d "dist" ]; then
        find dist -name "*.js" -o -name "*.css" | while read file; do
            if [ -f "$file" ]; then
                size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                size_formatted=$(format_bytes $size_bytes)
                gzipped_bytes=$(gzip -c "$file" | wc -c)
                gzipped_formatted=$(format_bytes $gzipped_bytes)
                filename=$(basename "$file")

                # Determine status based on file size
                if [ "$size_bytes" -gt 1048576 ]; then
                    status="${RED}⚠️  Large (>1MB)${NC}"
                elif [ "$size_bytes" -gt 524288 ]; then
                    status="${YELLOW}⚡ Medium (>512KB)${NC}"
                else
                    status="${GREEN}✅ Optimal${NC}"
                fi

                printf "%-40s %-10s %-12s %-15s\n" "$filename" "$size_formatted" "$gzipped_formatted" "$status"

                total_size=$((total_size + size_bytes))
                file_count=$((file_count + 1))
            fi
        done

        echo "--------------------------------------------------------------------------------"
        echo "Total files: $file_count"
        echo "Total size: $(format_bytes $total_size)"
    else
        log_warning "No dist directory found, build may have failed"
    fi

    echo ""
    echo "🚀 Bundle Optimization Recommendations:"
    echo "- Use code splitting for large bundles"
    echo "- Enable tree shaking to remove unused code"
    echo "- Consider lazy loading for non-critical components"
    echo "- Optimize images and use modern formats (WebP, AVIF)"
    echo "- Use dynamic imports for route-based code splitting"
    echo "- Minimize and compress CSS and JavaScript"

    cd ../..
}

# Function to show summary and recommendations
show_summary() {
    echo ""
    echo "📋 Size Analysis Summary"
    echo "======================="
    echo ""
    echo "✅ Analysis complete! Review the recommendations above to optimize your build sizes."
    echo ""
    echo "💡 Pro Tips:"
    echo "- Run this script regularly during development"
    echo "- Set up size budgets in your CI/CD pipeline"
    echo "- Monitor size changes in pull requests"
    echo "- Use webpack-bundle-analyzer for detailed web bundle analysis"
    echo ""
    echo "🔗 Useful Commands:"
    echo "- pnpm build:contracts  # Build contracts only"
    echo "- pnpm build           # Build all packages"
    echo "- forge build --sizes  # Show contract sizes"
    echo ""
}

# Main function
main() {
    echo ""
    log_info "🔍 LilNouns ENS Build Size Analysis"
    echo ""

    # Analyze contracts
    if ! analyze_contracts; then
        log_error "Contract analysis failed"
    fi

    # Analyze web bundles
    if ! analyze_web_bundles; then
        log_error "Web bundle analysis failed"
    fi

    # Show summary
    show_summary
}

# Run main function
main "$@"
