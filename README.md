# ChatMate

一个完全运行在 iOS 设备上的本地 AI 聊天应用，基于 llama.cpp 实现。

## ✨ 特性

- 🚀 **完全本地运行**：所有推理在设备上完成，无需网络
- 🔒 **隐私保护**：对话数据完全保存在本地，不上传云端
- 💬 **流式输出**：逐字显示 AI 回复，体验流畅
- 🎯 **轻量级**：使用量化模型，内存占用低
- 📱 **原生 iOS**：SwiftUI 开发，界面现代美观

## 📋 系统要求

- iOS 15.0+
- Xcode 15.0+
- iPhone/iPad（推荐 2GB+ RAM）

## 🛠️ 技术栈

- **语言**：Swift 5.9+
- **UI 框架**：SwiftUI
- **AI 引擎**：llama.cpp
- **架构**：MVVM

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/yourusername/ChatMate.git
cd ChatMate
```

### 2. 下载预编译的 llama.cpp XCFramework

```bash
cd ~/Downloads
curl -L -o llama-xcframework.zip "https://github.com/ggml-org/llama.cpp/releases/download/b5046/llama-b5046-xcframework.zip"
unzip llama-xcframework.zip
```

### 3. 在 Xcode 中配置

1. 打开 `ChatMate/ChatMate.xcodeproj`
2. 将 `~/Downloads/build-apple/llama.xcframework` 拖入项目
3. 设置 Target：`TARGETS` → `ChatMate` → `General`
4. 在 `Frameworks, Libraries, and Embedded Content` 中
5. 确保 `llama.xcframework` 的 Embed 设置为 **"Embed & Sign"**

### 4. 添加模型文件

#### 方式 A：打包到 App（推荐用于测试）

1. 下载量化模型（推荐 Q4）：
   ```bash
   # 例如从 Hugging Face 下载 Qwen2.5 模型
   # https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF
   ```

2. 在 Xcode 中创建 `Models` 文件夹
3. 将 `.gguf` 文件拖入项目
4. 勾选 `Copy items if needed`

#### 方式 B：首次运行下载（推荐用于发布）

参考 `真机部署指南.md` 中的实现方案。

### 5. 编译运行

```bash
# 模拟器
⌘ + R

# 真机
连接 iPhone → 选择设备 → ⌘ + R
```

## 📱 使用说明

1. **首次启动**：App 会自动加载模型（需要 10-30 秒）
2. **发送消息**：在底部输入框输入文字，点击发送
3. **查看回复**：AI 回复会逐字显示
4. **清空对话**：点击右上角菜单 → 清空对话

## 🎯 推荐模型

| 模型 | 大小 | 内存占用 | 速度 | 质量 |
|------|------|----------|------|------|
| Qwen2.5-1.5B Q4 | ~1GB | ~1.5GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Qwen2.5-3B Q4 | ~2GB | ~2.5GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Qwen2.5-7B Q4 | ~4GB | ~5GB | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 📂 项目结构

```
ChatMate/
├── ChatMate/                    # iOS 应用代码
│   ├── Models/                  # 数据模型
│   │   └── Message.swift
│   ├── Views/                   # SwiftUI 视图
│   │   ├── ChatView.swift
│   │   ├── MessageBubbleView.swift
│   │   └── InputBarView.swift
│   ├── ViewModels/              # 视图模型
│   │   └── ChatViewModel.swift
│   ├── Services/                # 业务逻辑
│   │   ├── LLMService.swift
│   │   └── LibLlama.swift
│   ├── Assets.xcassets/         # 资源文件
│   └── ChatMateApp.swift        # App 入口
├── ChatMate.xcodeproj/          # Xcode 项目文件
├── llama.xcframework/           # llama.cpp 框架
├── docs/                        # 开发文档
│   ├── 真机部署指南.md
│   ├── 使用预编译XCFramework.md
│   ├── 快速修复步骤.md
│   └── ...
├── scripts/                     # 工具脚本
│   ├── download_model.py
│   ├── clean_packages.sh
│   └── ...
├── README.md
└── .gitignore
```

## ⚠️ 注意事项

### 真机部署

- ✅ 必须将 `llama.xcframework` 设置为 **"Embed & Sign"**
- ✅ 首次安装会较慢（需传输大文件）
- ✅ 确保设备有足够存储空间（至少 2GB）

### 性能优化

- 使用 Q4 量化可以平衡速度和质量
- 关闭后台应用释放内存
- 避免在低电量时运行（推理消耗电量）

## 🐛 常见问题

### Q: 真机崩溃 "Library not loaded: llama.framework"

**A**: `llama.xcframework` 未正确嵌入。解决：
1. Xcode → General → Frameworks, Libraries, and Embedded Content
2. 将 `llama.xcframework` 改为 **"Embed & Sign"**

详见 `快速修复步骤.md`

### Q: 模型加载失败

**A**: 检查：
1. 模型文件是否在 Bundle 或 Documents 中
2. 路径是否正确
3. 文件是否完整（未损坏）

### Q: 回复速度慢

**A**: 
1. 使用更小的模型（Q2/Q3 量化）
2. 减少上下文长度
3. 在性能更好的设备上运行

## 📄 License

MIT License

## 🙏 致谢

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - 核心推理引擎
- [Qwen](https://github.com/QwenLM/Qwen) - 优秀的开源模型

## 📮 联系方式

- 问题反馈：[GitHub Issues](https://github.com/yourusername/ChatMate/issues)
- 讨论交流：[GitHub Discussions](https://github.com/yourusername/ChatMate/discussions)

---

⭐ 如果这个项目对你有帮助，请给个 Star！
