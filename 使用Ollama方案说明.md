# ChatMate - 使用 Ollama API 方案

## 🎯 方案说明

由于 llama.cpp 的 Swift Package 不完善，我们采用了更简单实用的方案：
- **iOS 模拟器** → 通过 HTTP 调用 → **Mac 上的 Ollama 服务** → **运行 Qwen 模型**

### 优势
- ✅ 无需复杂的 C++ 集成
- ✅ 纯 Swift 实现，代码简洁
- ✅ 立即可用，真实 AI 对话
- ✅ 开发调试方便

### 架构
```
┌──────────────────┐
│  iOS 模拟器       │
│  ChatMate App    │
│  (Swift)         │
└────────┬─────────┘
         │ HTTP API
         │ localhost:11434
         ▼
┌──────────────────┐
│  Mac 电脑         │
│  Ollama 服务      │
│  (chatmate 模型)  │
└──────────────────┘
```

## ✅ 已完成的更新

### 1. LLMService.swift
- 实现了 Ollama HTTP API 调用
- 支持流式输出（逐字显示）
- 错误处理和状态管理

### 2. API 接口
```swift
// 检查服务：GET /api/tags
// 生成文本：POST /api/generate
{
  "model": "chatmate",
  "prompt": "用户输入",
  "stream": true
}
```

## 🚀 测试步骤

### 1. 确保 Ollama 运行
```bash
# 检查 Ollama 是否运行
curl http://localhost:11434/api/tags

# 如果没运行，启动它
ollama serve
```

### 2. 确认模型存在
```bash
ollama list
# 应该看到 chatmate 模型
```

### 3. 在 Xcode 中编译运行
1. **清理之前的包依赖**
   - File → Packages → Reset Package Caches
   
2. **编译项目**
   - ⌘ + B
   
3. **运行应用**
   - ⌘ + R
   
4. **测试对话**
   - 输入："你好"
   - 应该看到真实的 AI 回复！

## 🔧 如果遇到问题

### 问题 1：连接失败
```
错误：无法连接到 Ollama 服务
```

**解决：**
```bash
# 1. 检查 Ollama 是否运行
ps aux | grep ollama

# 2. 如果没运行，启动它
ollama serve

# 3. 测试连接
curl http://localhost:11434/api/tags
```

### 问题 2：模型不存在
```
错误：model 'chatmate' not found
```

**解决：**
```bash
# 检查模型列表
ollama list

# 如果没有 chatmate，重新创建
ollama create chatmate -f /tmp/Modelfile
```

### 问题 3：模拟器无法访问 localhost

iOS 模拟器可以直接访问 Mac 的 localhost，不需要额外配置。

如果真的有问题，可以改用：
- `http://127.0.0.1:11434`
- 或者查看 Mac 的局域网 IP：`ifconfig | grep inet`

## 📱 真机测试（可选）

如果要在真机上测试：

### 方法 1：使用 Mac 的局域网 IP
```swift
// 修改 LLMService.swift
private let ollamaBaseURL = "http://192.168.x.x:11434" // Mac 的 IP
```

### 方法 2：部署本地模型
后续可以使用 llama.cpp 将模型真正集成到 App 中。

## 🎓 后续优化方向

### 短期（开发阶段）
- ✅ 继续使用 Ollama API
- ✅ 完善 UI 和用户体验
- ✅ 添加历史记录、系统提示词等功能

### 中期（准备发布）
- 🔄 集成 llama.cpp iOS 库
- 🔄 将 GGUF 模型打包到 App
- 🔄 实现完全离线运行

### 长期（高级功能）
- 🔮 支持多个模型切换
- 🔮 模型动态下载
- 🔮 上下文记忆优化
- 🔮 语音输入输出

## 💡 关键代码解析

### 流式输出实现
```swift
// Ollama 返回的是 NDJSON（每行一个 JSON）
for try await line in bytes.lines {
    let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
    continuation.yield(response.response) // 逐字返回
}
```

### 取消生成
```swift
func cancelGeneration() {
    currentTask?.cancel() // Swift Task 取消
    // Ollama 会自动停止生成
}
```

## ✅ 现在就试试吧！

1. 确保 Ollama 运行：`ollama list`
2. 在 Xcode 中按 ⌘ + R
3. 输入消息，享受真实 AI 对话！

---

**遇到问题随时告诉我！** 🚀
