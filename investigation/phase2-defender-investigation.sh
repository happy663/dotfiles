#!/bin/bash

# Phase 2: Microsoft Defender重点調査
# バックグラウンドプロセス（特にDefender）とNeovim起動遅延の相関を調査

DURATION=${1:-60}  # 監視時間（分）デフォルト1時間
INTERVAL=${2:-30}  # 監視間隔（秒）デフォルト30秒
OUTPUT_FILE="phase2-defender-investigation-$(date +%Y%m%d-%H%M%S).log"

echo "=== Phase 2: Microsoft Defender重点調査 ===" | tee "$OUTPUT_FILE"
echo "開始時刻: $(date)" | tee -a "$OUTPUT_FILE"
echo "監視期間: ${DURATION}分" | tee -a "$OUTPUT_FILE"
echo "監視間隔: ${INTERVAL}秒" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Defender関連プロセスの確認
echo "=== Microsoft Defender関連プロセス確認 ===" | tee -a "$OUTPUT_FILE"
ps aux | grep -E "(wdav|defender|microsoft|epsext)" | grep -v grep | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Defenderの設定状況確認
echo "=== Defender設定確認 ===" | tee -a "$OUTPUT_FILE"
if command -v mdatp >/dev/null 2>&1; then
    echo "mdatp health:" | tee -a "$OUTPUT_FILE"
    mdatp health | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
    echo "mdatp config:" | tee -a "$OUTPUT_FILE"
    mdatp config show | tee -a "$OUTPUT_FILE"
else
    echo "mdatp コマンドが見つかりません" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 監視カウンタ
ITERATION=1
END_TIME=$(($(date +%s) + $DURATION * 60))

echo "=== 連続監視開始 ===" | tee -a "$OUTPUT_FILE"

while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date)
    echo "--- 測定 $ITERATION ($TIMESTAMP) ---" | tee -a "$OUTPUT_FILE"
    
    # Defenderプロセスの詳細状態
    echo "Microsoft Defender関連プロセス:" | tee -a "$OUTPUT_FILE"
    DEFENDER_PROCESSES=$(ps aux | grep -E "(wdav|defender|microsoft|epsext)" | grep -v grep)
    if [ -n "$DEFENDER_PROCESSES" ]; then
        echo "$DEFENDER_PROCESSES" | awk '{printf "  PID:%s CPU:%s%% MEM:%s%% CMD:%s\n", $2, $3, $4, $11}' | tee -a "$OUTPUT_FILE"
        
        # Defenderが高CPU使用している場合の詳細記録
        DEFENDER_HIGH_CPU=$(echo "$DEFENDER_PROCESSES" | awk '$3 > 20 {print $2}')
        if [ -n "$DEFENDER_HIGH_CPU" ]; then
            echo "  🚨 Defender高CPU使用検出！" | tee -a "$OUTPUT_FILE"
            for pid in $DEFENDER_HIGH_CPU; do
                echo "    PID $pid の詳細:" | tee -a "$OUTPUT_FILE"
                ps -o pid,etime,rss,cpu,command -p $pid 2>/dev/null | tail -1 | tee -a "$OUTPUT_FILE"
            done
        fi
    else
        echo "  Defenderプロセスが見つかりません" | tee -a "$OUTPUT_FILE"
    fi
    
    # システム全体の負荷状況
    echo "システム負荷:" | tee -a "$OUTPUT_FILE"
    echo "  CPU負荷: $(uptime | awk -F'load averages:' '{print $2}')" | tee -a "$OUTPUT_FILE"
    echo "  メモリ状況: $(vm_stat | grep 'Pages free' | awk '{print $3}' | tr -d '.')ページ" | tee -a "$OUTPUT_FILE"
    
    # CPU使用率上位プロセス（特にDefender以外も確認）
    echo "  CPU上位プロセス:" | tee -a "$OUTPUT_FILE"
    ps aux | sort -k3 -nr | head -6 | tail -5 | awk '{printf "    %s%% %s\n", $3, $11}' | tee -a "$OUTPUT_FILE"
    
    # ファイルアクセス監視（Defenderがアクセスしているファイル）
    echo "  最近のファイルアクセス（Defender関連）:" | tee -a "$OUTPUT_FILE"
    timeout 2 sudo fs_usage -f pathname wdav 2>/dev/null | head -5 | awk '{print "    " $0}' | tee -a "$OUTPUT_FILE" || echo "    ファイルアクセス監視: タイムアウト" | tee -a "$OUTPUT_FILE"
    
    # Neovim起動時間測定（3回平均）
    echo "Neovim起動時間測定:" | tee -a "$OUTPUT_FILE"
    TOTAL_TIME=0
    for i in 1 2 3; do
        # 起動直前のDefender状態記録
        if [ $i -eq 1 ]; then
            DEFENDER_CPU_BEFORE=$(ps aux | grep -E "(wdav|epsext)" | grep -v grep | awk '{sum+=$3} END {printf "%.1f", sum}')
            echo "  起動前Defender CPU使用率: ${DEFENDER_CPU_BEFORE}%" | tee -a "$OUTPUT_FILE"
        fi
        
        START_TIME=$(python3 -c "import time; print(time.time())")
        nvim --startuptime "/tmp/phase2-startup-$i.log" +q
        END_TIME_NVIM=$(python3 -c "import time; print(time.time())")
        DURATION_MS=$(python3 -c "print(int(($END_TIME_NVIM - $START_TIME) * 1000))")
        
        # 起動後のDefender状態記録
        if [ $i -eq 1 ]; then
            DEFENDER_CPU_AFTER=$(ps aux | grep -E "(wdav|epsext)" | grep -v grep | awk '{sum+=$3} END {printf "%.1f", sum}')
            echo "  起動後Defender CPU使用率: ${DEFENDER_CPU_AFTER}%" | tee -a "$OUTPUT_FILE"
        fi
        
        TOTAL_TIME=$((TOTAL_TIME + DURATION_MS))
        echo "  測定$i: ${DURATION_MS}ms" | tee -a "$OUTPUT_FILE"
    done
    
    AVERAGE_TIME=$((TOTAL_TIME / 3))
    echo "  平均起動時間: ${AVERAGE_TIME}ms" | tee -a "$OUTPUT_FILE"
    
    # Defenderの影響度判定
    if [ -n "$DEFENDER_CPU_BEFORE" ] && [ -n "$DEFENDER_CPU_AFTER" ]; then
        if (( $(echo "$DEFENDER_CPU_BEFORE > 30" | bc -l) )); then
            echo "  💡 Defender高負荷時の起動: ${AVERAGE_TIME}ms" | tee -a "$OUTPUT_FILE"
        elif (( $(echo "$DEFENDER_CPU_BEFORE < 5" | bc -l) )); then
            echo "  ✅ Defender低負荷時の起動: ${AVERAGE_TIME}ms" | tee -a "$OUTPUT_FILE"
        fi
    fi
    
    # 詳細なstartuptimeログからDefender関連の遅延を分析
    if [ -f "/tmp/phase2-startup-1.log" ]; then
        echo "  起動詳細分析:" | tee -a "$OUTPUT_FILE"
        FINAL_TIME=$(tail -1 "/tmp/phase2-startup-1.log" | awk '{print $1}')
        echo "    内部測定時間: ${FINAL_TIME}ms" | tee -a "$OUTPUT_FILE"
        
        # 重い処理を特定
        HEAVY_PROCESSES=$(awk '{if($2 >= 50) print $1, $2, $4}' "/tmp/phase2-startup-1.log" | sort -k2 -nr | head -3)
        if [ -n "$HEAVY_PROCESSES" ]; then
            echo "    重い処理（50ms以上）:" | tee -a "$OUTPUT_FILE"
            echo "$HEAVY_PROCESSES" | while read line; do
                echo "      $line" | tee -a "$OUTPUT_FILE"
            done
        fi
    fi
    
    echo "" | tee -a "$OUTPUT_FILE"
    
    # クリーンアップ
    rm -f /tmp/phase2-startup-*.log
    
    ITERATION=$((ITERATION + 1))
    
    # 次の測定まで待機
    if [ $(date +%s) -lt $END_TIME ]; then
        sleep $INTERVAL
    fi
done

echo "=== Phase 2 調査完了 ===" | tee -a "$OUTPUT_FILE"
echo "完了時刻: $(date)" | tee -a "$OUTPUT_FILE"
echo "総測定回数: $((ITERATION - 1))回" | tee -a "$OUTPUT_FILE"

# 簡易分析
echo "=== 簡易分析 ===" | tee -a "$OUTPUT_FILE"
echo "起動時間の変化:" | tee -a "$OUTPUT_FILE"
grep "平均起動時間:" "$OUTPUT_FILE" | nl | tee -a "$OUTPUT_FILE"

echo "Defender高負荷時の起動時間:" | tee -a "$OUTPUT_FILE"
grep "Defender高負荷時の起動:" "$OUTPUT_FILE" || echo "該当なし" | tee -a "$OUTPUT_FILE"

echo "Defender低負荷時の起動時間:" | tee -a "$OUTPUT_FILE"
grep "Defender低負荷時の起動:" "$OUTPUT_FILE" || echo "該当なし" | tee -a "$OUTPUT_FILE"

echo "結果ファイル: $OUTPUT_FILE"
echo "Phase 2: Microsoft Defender調査完了！"