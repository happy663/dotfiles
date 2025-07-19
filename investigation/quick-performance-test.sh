#!/bin/bash

# 短期テスト用: 3分間隔でのNeovim性能チェック
# 最適化効果の即座確認に使用

WAIT_MINUTES=${1:-3}  # 待機時間（分）デフォルト3分
OUTPUT_FILE="quick-performance-test-$(date +%Y%m%d-%H%M%S).log"

echo "=== 短期性能テスト（${WAIT_MINUTES}分間隔） ===" | tee "$OUTPUT_FILE"
echo "開始時刻: $(date)" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 即座測定（現在の状態）
echo "=== 即座測定 ====" | tee -a "$OUTPUT_FILE"
IMMEDIATE_TOTAL=0
for i in 1 2 3; do
    START_TIME=$(python3 -c "import time; print(time.time())")
    nvim --startuptime "/tmp/immediate-$i.log" +q
    END_TIME=$(python3 -c "import time; print(time.time())")
    DURATION_MS=$(python3 -c "print(int(($END_TIME - $START_TIME) * 1000))")
    
    IMMEDIATE_TOTAL=$((IMMEDIATE_TOTAL + DURATION_MS))
    echo "  即座測定$i: ${DURATION_MS}ms" | tee -a "$OUTPUT_FILE"
    rm -f "/tmp/immediate-$i.log"
done

IMMEDIATE_AVERAGE=$((IMMEDIATE_TOTAL / 3))
echo "  即座平均: ${IMMEDIATE_AVERAGE}ms" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 待機
echo "=== ${WAIT_MINUTES}分待機中 ===" | tee -a "$OUTPUT_FILE"
for min in $(seq 1 $WAIT_MINUTES); do
    echo "  ${min}分経過..." | tee -a "$OUTPUT_FILE"
    sleep 60
done
echo "" | tee -a "$OUTPUT_FILE"

# 待機後測定
echo "=== ${WAIT_MINUTES}分後測定 ===" | tee -a "$OUTPUT_FILE"
echo "システム状態:" | tee -a "$OUTPUT_FILE"
echo "  メモリ: $(vm_stat | grep 'Pages free' | awk '{print $3}' | tr -d '.')ページ" | tee -a "$OUTPUT_FILE"
echo "  Defender CPU: $(ps aux | grep -E "(wdav|epsext)" | grep -v grep | awk '{sum+=$3} END {printf "%.1f", sum}')%" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

DELAYED_TOTAL=0
for i in 1 2 3; do
    START_TIME=$(python3 -c "import time; print(time.time())")
    nvim --startuptime "/tmp/delayed-$i.log" +q
    END_TIME=$(python3 -c "import time; print(time.time())")
    DURATION_MS=$(python3 -c "print(int(($END_TIME - $START_TIME) * 1000))")
    
    DELAYED_TOTAL=$((DELAYED_TOTAL + DURATION_MS))
    echo "  ${WAIT_MINUTES}分後測定$i: ${DURATION_MS}ms" | tee -a "$OUTPUT_FILE"
    
    # 詳細分析（最初の測定のみ）
    if [ $i -eq 1 ]; then
        INTERNAL_TIME=$(tail -1 "/tmp/delayed-$i.log" | awk '{print $1}')
        echo "    内部測定時間: ${INTERNAL_TIME}ms" | tee -a "$OUTPUT_FILE"
        
        # 重い処理を特定
        HEAVY_PROCESSES=$(awk '{if($2 >= 50) print $1, $2, $4}' "/tmp/delayed-$i.log" | sort -k2 -nr | head -3)
        if [ -n "$HEAVY_PROCESSES" ]; then
            echo "    重い処理（50ms以上）:" | tee -a "$OUTPUT_FILE"
            echo "$HEAVY_PROCESSES" | while read line; do
                echo "      $line" | tee -a "$OUTPUT_FILE"
            done
        fi
    fi
    
    rm -f "/tmp/delayed-$i.log"
done

DELAYED_AVERAGE=$((DELAYED_TOTAL / 3))
echo "  ${WAIT_MINUTES}分後平均: ${DELAYED_AVERAGE}ms" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 結果分析
DIFFERENCE=$((DELAYED_AVERAGE - IMMEDIATE_AVERAGE))
CHANGE_PERCENT=$(python3 -c "print(int($DIFFERENCE * 100 / $IMMEDIATE_AVERAGE))" 2>/dev/null || echo "0")

echo "=== 結果サマリー ===" | tee -a "$OUTPUT_FILE"
echo "即座測定平均: ${IMMEDIATE_AVERAGE}ms" | tee -a "$OUTPUT_FILE"
echo "${WAIT_MINUTES}分後平均: ${DELAYED_AVERAGE}ms" | tee -a "$OUTPUT_FILE"
echo "変化: ${DIFFERENCE}ms (${CHANGE_PERCENT}%変化)" | tee -a "$OUTPUT_FILE"

if [ $DIFFERENCE -gt 300 ]; then
    echo "🚨 ${WAIT_MINUTES}分後に大幅遅延発生" | tee -a "$OUTPUT_FILE"
elif [ $DIFFERENCE -gt 100 ]; then
    echo "⚠️  ${WAIT_MINUTES}分後に軽微な遅延" | tee -a "$OUTPUT_FILE"
elif [ $DIFFERENCE -lt -100 ]; then
    echo "🎯 ${WAIT_MINUTES}分後により高速化" | tee -a "$OUTPUT_FILE"
else
    echo "✅ ${WAIT_MINUTES}分後も安定した性能" | tee -a "$OUTPUT_FILE"
fi

echo "" | tee -a "$OUTPUT_FILE"
echo "完了時刻: $(date)" | tee -a "$OUTPUT_FILE"
echo "結果ファイル: $OUTPUT_FILE"
echo "短期性能テスト完了！"