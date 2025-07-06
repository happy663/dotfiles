# Neovim Performance Investigation

## Overview
This directory contains all investigation materials for Neovim startup performance issue #116.

## Key Files

### 📊 Main Report
- `NEOVIM_PERFORMANCE_INVESTIGATION.md` - Complete investigation report

### 🛠️ Scripts

#### 短期テスト用（設定変更後の即座確認）
- `quick-performance-test.sh` ⚡ - **Quick test** (3-minute interval, ~6 minutes total)

#### 長期監視用（安定性・再現性確認）  
- `long-interval-test.sh` ⭐ - **Comprehensive test** (6-minute interval, ~30 minutes total)

#### 調査用（参考）
- `phase2-defender-investigation.sh` - Microsoft Defender investigation

### 📋 Logs
- `long-interval-test-20250706-001847.log` - Final test results showing 59% improvement

## Quick Start

### 短期テスト（最適化効果の即座確認）
```bash
cd investigation
./quick-performance-test.sh 3  # 3分間隔テスト（約6分）
```

### 長期テスト（安定性確認）
```bash
./long-interval-test.sh 5 6  # 5回測定、6分間隔（約30分）
```

### Check Microsoft Defender exclusions:
```bash
mdatp exclusion list
```

## Key Findings

1. **Microsoft Defender** was the primary cause of startup delays
2. **Exclusion settings** reduced startup time by 59%
3. **Telescope plugin** remains a secondary performance bottleneck
4. **6-minute intervals** reliably reproduce the issue

## Status
- ✅ Microsoft Defender impact resolved (59% improvement)
- ⚠️ Telescope plugin optimization pending
- 🛠️ Monitoring tools in place for ongoing analysis