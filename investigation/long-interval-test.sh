#!/bin/bash

# 5-6分間隔でのNeovim起動時間測定
# issue #116の「2-3分後に遅くなる」現象を正確に検証

ITERATIONS=${1:-5}  # 測定回数デフォルト5回
INTERVAL_MINUTES=${2:-6}  # 間隔（分）デフォルト6分
OUTPUT_FILE="long-interval-test-$(date +%Y%m%d-%H%M%S).log"

echo "=== 長期間隔測定（Defender除外設定後） ===" | tee "$OUTPUT_FILE"
echo "開始時刻: $(date)" | tee -a "$OUTPUT_FILE"
echo "測定回数: ${ITERATIONS}回" | tee -a "$OUTPUT_FILE"
echo "測定間隔: ${INTERVAL_MINUTES}分" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 最後のneovimプロセス起動時刻を確認
echo "=== 初回測定前の状況確認 ===" | tee -a "$OUTPUT_FILE"
LAST_NVIM_PID=$(pgrep nvim | tail -1)
if [ -n "$LAST_NVIM_PID" ]; then
    LAST_NVIM_START=$(ps -o lstart= -p $LAST_NVIM_PID 2>/dev/null)
    echo "現在実行中のneovim: PID $LAST_NVIM_PID (開始: $LAST_NVIM_START)" | tee -a "$OUTPUT_FILE"
else
    echo "現在実行中のneovimプロセスなし" | tee -a "$OUTPUT_FILE"
fi

# /tmp内の最近のstartuptimeログを確認
RECENT_STARTUP_LOG=$(ls -t /tmp/*startup*.log 2>/dev/null | head -1)
if [ -n "$RECENT_STARTUP_LOG" ]; then
    LAST_LOG_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$RECENT_STARTUP_LOG" 2>/dev/null)
    echo "最後のstartuptimeログ: $RECENT_STARTUP_LOG ($LAST_LOG_TIME)" | tee -a "$OUTPUT_FILE"
    
    # 経過時間計算
    LAST_LOG_EPOCH=$(stat -f "%m" "$RECENT_STARTUP_LOG" 2>/dev/null)
    CURRENT_EPOCH=$(date +%s)
    if [ -n "$LAST_LOG_EPOCH" ]; then
        ELAPSED_MINUTES=$(((CURRENT_EPOCH - LAST_LOG_EPOCH) / 60))
        echo "最後のneovim起動からの経過時間: ${ELAPSED_MINUTES}分" | tee -a "$OUTPUT_FILE"
        
        if [ $ELAPSED_MINUTES -lt $INTERVAL_MINUTES ]; then
            WAIT_TIME=$((INTERVAL_MINUTES - ELAPSED_MINUTES))
            echo "⚠️  ${WAIT_TIME}分追加で待機してから測定開始します..." | tee -a "$OUTPUT_FILE"
            for min in $(seq 1 $WAIT_TIME); do
                echo "  追加待機 ${min}分..." | tee -a "$OUTPUT_FILE"
                sleep 60
            done
        fi
    fi
else
    echo "最近のstartuptimeログなし" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

for i in $(seq 1 $ITERATIONS); do
    TIMESTAMP=$(date)
    echo "=== 測定 $i/$ITERATIONS ($TIMESTAMP) ===" | tee -a "$OUTPUT_FILE"
    
    # システム状態記録
    echo "システム状態:" | tee -a "$OUTPUT_FILE"
    echo "  メモリ: $(vm_stat | grep 'Pages free' | awk '{print $3}' | tr -d '.')ページ" | tee -a "$OUTPUT_FILE"
    echo "  CPU負荷: $(uptime | awk -F'load averages:' '{print $2}')" | tee -a "$OUTPUT_FILE"
    
    # Defender状態
    DEFENDER_CPU=$(ps aux | grep -E "(wdav|epsext)" | grep -v grep | awk '{sum+=$3} END {printf "%.1f", sum}')
    echo "  Defender CPU使用率: ${DEFENDER_CPU}%" | tee -a "$OUTPUT_FILE"
    
    # Neovim起動時間測定（3回平均）
    echo "Neovim起動時間測定:" | tee -a "$OUTPUT_FILE"
    TOTAL_TIME=0
    for j in 1 2 3; do
        START_TIME=$(python3 -c "import time; print(time.time())")
        nvim --startuptime "/tmp/long-test-${i}-${j}.log" +q
        END_TIME=$(python3 -c "import time; print(time.time())")
        DURATION_MS=$(python3 -c "print(int(($END_TIME - $START_TIME) * 1000))")
        
        TOTAL_TIME=$((TOTAL_TIME + DURATION_MS))
        echo "  測定${j}: ${DURATION_MS}ms" | tee -a "$OUTPUT_FILE"
        
        # 詳細分析（最初の測定のみ）
        if [ $j -eq 1 ]; then
            INTERNAL_TIME=$(tail -1 "/tmp/long-test-${i}-${j}.log" | awk '{print $1}')
            echo "    内部測定時間: ${INTERNAL_TIME}ms" | tee -a "$OUTPUT_FILE"
            
            # 重い処理を特定
            HEAVY_PROCESSES=$(awk '{if($2 >= 50) print $1, $2, $4}' "/tmp/long-test-${i}-${j}.log" | sort -k2 -nr | head -3)
            if [ -n "$HEAVY_PROCESSES" ]; then
                echo "    重い処理（50ms以上）:" | tee -a "$OUTPUT_FILE"
                echo "$HEAVY_PROCESSES" | while read line; do
                    echo "      $line" | tee -a "$OUTPUT_FILE"
                done
            fi
        fi
        
        rm -f "/tmp/long-test-${i}-${j}.log"
    done
    
    AVERAGE_TIME=$((TOTAL_TIME / 3))
    echo "  平均起動時間: ${AVERAGE_TIME}ms" | tee -a "$OUTPUT_FILE"
    
    # 遅延判定
    if [ $AVERAGE_TIME -gt 1000 ]; then
        echo "  🚨 大幅な遅延検出！ issue #116再現" | tee -a "$OUTPUT_FILE"
    elif [ $AVERAGE_TIME -gt 700 ]; then
        echo "  ⚠️  中程度の遅延検出" | tee -a "$OUTPUT_FILE"
    else
        echo "  ✅ 正常な起動時間" | tee -a "$OUTPUT_FILE"
    fi
    
    # 前回測定との比較
    if [ $i -gt 1 ]; then
        PREV_TIME=$(grep "平均起動時間:" "$OUTPUT_FILE" | tail -2 | head -1 | awk '{print $2}' | tr -d 'ms')
        DIFF=$((AVERAGE_TIME - PREV_TIME))
        CHANGE_PERCENT=$(python3 -c "print(int($DIFF * 100 / $PREV_TIME))" 2>/dev/null || echo "0")
        echo "  変化: ${DIFF}ms (${CHANGE_PERCENT}%変化)" | tee -a "$OUTPUT_FILE"
    fi
    
    echo "" | tee -a "$OUTPUT_FILE"
    
    # 次の測定まで待機（最後の測定以外）
    if [ $i -lt $ITERATIONS ]; then
        echo "次の測定まで${INTERVAL_MINUTES}分待機..." | tee -a "$OUTPUT_FILE"
        for min in $(seq 1 $INTERVAL_MINUTES); do
            echo "  ${min}分経過..." | tee -a "$OUTPUT_FILE"
            sleep 60
        done
        echo "" | tee -a "$OUTPUT_FILE"
    fi
done

echo "=== 測定完了 ===" | tee -a "$OUTPUT_FILE"
echo "完了時刻: $(date)" | tee -a "$OUTPUT_FILE"

# 結果サマリー
echo "=== 結果サマリー ===" | tee -a "$OUTPUT_FILE"
echo "各測定の平均起動時間:" | tee -a "$OUTPUT_FILE"
grep "平均起動時間:" "$OUTPUT_FILE" | nl | tee -a "$OUTPUT_FILE"

echo "遅延検出:" | tee -a "$OUTPUT_FILE"
grep -E "(大幅な遅延|中程度の遅延)" "$OUTPUT_FILE" || echo "遅延なし" | tee -a "$OUTPUT_FILE"

echo "結果ファイル: $OUTPUT_FILE"
echo "長期間隔測定完了！"