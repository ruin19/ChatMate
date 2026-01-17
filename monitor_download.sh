#!/bin/bash
# 实时监控模型下载进度

echo "📥 监控 Qwen2.5-1.5B 模型下载进度..."
echo "按 Ctrl+C 停止监控（不会中断下载）"
echo ""

MODEL_DIR="$HOME/Downloads/ChatMate-Models"
CACHE_DIR="$HOME/.cache/huggingface"

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Qwen2.5-1.5B 模型下载进度监控                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 检查下载进程
    if ps aux | grep -q "[p]ython3 download_model.py"; then
        echo "✅ 下载进程: 运行中"
    else
        echo "⚠️  下载进程: 未运行"
    fi
    
    echo ""
    echo "📂 目标目录: $MODEL_DIR"
    
    # 检查目标文件
    if [ -f "$MODEL_DIR/qwen2.5-1.5b-instruct-q4_k_m.gguf" ]; then
        SIZE=$(stat -f%z "$MODEL_DIR/qwen2.5-1.5b-instruct-q4_k_m.gguf" 2>/dev/null)
        SIZE_MB=$((SIZE / 1024 / 1024))
        SIZE_GB=$(echo "scale=2; $SIZE / 1024 / 1024 / 1024" | bc)
        PERCENT=$(echo "scale=1; $SIZE / 1073741824 * 100" | bc)
        
        echo "📦 文件大小: ${SIZE_MB} MB (${SIZE_GB} GB) - ${PERCENT}%"
        
        if [ $SIZE -gt 1000000000 ]; then
            echo ""
            echo "🎉 下载完成！"
            break
        fi
    else
        echo "📦 文件大小: 下载中..."
    fi
    
    # 检查缓存目录
    if [ -d "$CACHE_DIR" ]; then
        CACHE_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
        echo "💾 缓存大小: $CACHE_SIZE"
    fi
    
    echo ""
    echo "⏰ 更新时间: $(date '+%H:%M:%S')"
    echo ""
    echo "提示: 等待下载完成后，我们将创建 Xcode 项目并集成模型"
    
    sleep 5
done
