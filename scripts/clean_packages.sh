#!/bin/bash

echo "🧹 ChatMate - 清理 Package 依赖脚本"
echo "=================================="
echo ""

# 关闭 Xcode
echo "1️⃣  关闭 Xcode..."
killall Xcode 2>/dev/null
sleep 1

# 进入项目目录
cd "$(dirname "$0")/ChatMate"

# 删除 SPM 相关文件
echo "2️⃣  删除 Package 文件..."
rm -rf ChatMate.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
rm -rf ChatMate.xcodeproj/xcuserdata
rm -f Package.resolved

# 清理 Xcode 缓存
echo "3️⃣  清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*

# 清理项目构建产物
echo "4️⃣  清理构建产物..."
rm -rf build/
rm -rf .build/

echo ""
echo "✅ 清理完成！"
echo ""
echo "📝 接下来的步骤："
echo "   1. 运行: open ChatMate.xcodeproj"
echo "   2. 在 Xcode 中: File → Add Package Dependencies..."
echo "   3. 输入 URL: https://github.com/ggerganov/llama.cpp"
echo "   4. 选择 Branch: master"
echo "   5. 只勾选产品: llama"
echo ""
