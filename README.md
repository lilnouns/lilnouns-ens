
# Lil Nouns ENS

[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/lilnouns/lilnouns-ens?include_prereleases)](https://github.com/lilnouns/lilnouns-ens/releases)
[![GitHub Workflow Status (branch)](https://img.shields.io/github/actions/workflow/status/lilnouns/lilnouns-ens/build.yml)](https://github.com/lilnouns/lilnouns-ens/actions/workflows/build.yml)
[![GitHub](https://img.shields.io/github/license/lilnouns/lilnouns-ens)](https://github.com/lilnouns/lilnouns-ens/blob/master/LICENSE)
[![X (formerly Twitter) Follow](https://img.shields.io/badge/follow-%40nekofar-ffffff?logo=x&style=flat)](https://x.com/nekofar)
[![Farcaster (Warpcast) Follow](https://img.shields.io/badge/follow-%40nekofar-855DCD.svg?logo=farcaster&logoColor=f5f5f5&style=flat)](https://warpcast.com/nekofar)
[![Donate](https://img.shields.io/badge/donate-nekofar.crypto-a2b9bc?logo=ethereum&logoColor=f5f5f5)](https://ud.me/nekofar.crypto)

> [!WARNING]
> Please note that the project is currently in an experimental phase, and it is subject to significant changes as it
> progresses.

## Overview

Lil Nouns ENS is a monorepo for developing and shipping an Ethereum Name Service (ENS) integration for Lil Nouns. It contains a web dApp, smart contracts, and a shared UI library, enabling end‑to‑end development from contracts to frontend.

## Structure

- apps/web: Vite + React dApp for interacting with the contracts
- packages/contracts: Smart contracts (Foundry + Hardhat) with tests and scripts
- packages/ui: Shared React UI components and hooks used by the dApp

## Key Components

- Web dApp: Built with Vite, React, Wagmi, and Viem
- Contracts: Foundry (forge) + Hardhat toolchains, TypeChain types
- UI Library: Reusable components (shadcn/radix), hooks, styles

## Getting Started

Basic commands for local development:

- Install: `pnpm install` (Node 22, pnpm 10)
- Dev (all): `pnpm dev` or web only: `pnpm -C apps/web dev`
- Build (all): `pnpm build`; Clean: `pnpm clean`
- Lint/Format: `pnpm lint`, `pnpm format`
- Test (all): `pnpm test`

Contracts:

- Foundry: `pnpm -C packages/contracts build:forge`, `test:forge`
- Hardhat: `pnpm -C packages/contracts build:hardhat`, `test:hardhat`
