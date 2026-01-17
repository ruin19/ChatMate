#!/bin/bash
# 检查模型下载进度

MODEL_DIR="$HOME/Downloads/ChatMate-Models"
MODEL_FILE="qwen2.5-1.5b-instruct-q4_k_m.gguf"
EXPECTED_SIZE=1073741824  # 约1GB

echo "=== 检查模型下载状态 ==="
echo ""

if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    CURRENT_SIZE=$(stat -f%z "$MODEL_DIR/$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_DIR/$MODEL_FILE" 2>/dev/null)
    SIZE_MB=$((CURRENT_SIZE / 1024 / 1024))
    SIZE_GB=$(echo "scale=2; $CURRENT_SIZE / 1024 / 1024 / 1024" | bc)
    
    echo "✅ 找到模型文件:"
    echo "   路径: $MODEL_DIR/$MODEL_FILE"
    echo "   大小: ${SIZE_MB} MB (${SIZE_GB} GB)"
    
    if [ $CURRENT_SIZE -gt 900000000 ]; then
        echo ""
        echo "🎉 下载完成！模型已就绪"
        exit 0
    else
        echo ""
        echo "⏳ 下载中... (${SIZE_MB} MB)"
        exit 2
    fi
else
    # 检查是否有临时文件
    if [ -d "$MODEL_DIR" ]; then
        TEMP_FILES=$(find "$MODEL_DIR" -name "*.tmp" -o -name "*.incomplete" 2>/dev/null)
        if [ -n "$TEMP_FILES" ]; then
            echo "⏳ 模型正在下载中..."
            ls -lh "$MODEL_DIR"
        else
            echo "❌ 未找到模型文件"
            echo "   目录: $MODEL_DIR"
            echo "   文件: $MODEL_FILE"
        fi
    else
        echo "❌ 模型目录不存在: $MODEL_DIR"
    fi
    exit 1
fi
