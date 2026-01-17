# 使用预编译 XCFramework - 最终解决方案 🎯

## ✅ 准备完成

预编译的 llama.xcframework 已下载到：
```
~/Downloads/build-apple/llama.xcframework
```

## 📱 在 Xcode 中的完整操作

### 第一步：清理旧的依赖

在 **ChatMate 项目**中：
1. 点击项目文件（蓝色图标）
2. `Package Dependencies` 标签
3. 删除所有 llama.cpp 相关 Package

### 第二步：添加 XCFramework

#### 方法 1：拖拽添加（最简单）

1. **打开 Finder**
   ```bash
   open ~/Downloads/build-apple/
   ```

2. **拖入 Xcode**
   - 将 `llama.xcframework` 拖入 Xcode 左侧项目导航器
   - 拖到 `ChatMate/ChatMate` 文件夹下
   - 弹出对话框时：
     - ✅ Copy items if needed
     - ✅ ChatMate (Target)
   - 点击 `Finish`

#### 方法 2：手动添加

1. **Target → General**
2. 滚动到 `Frameworks, Libraries, and Embedded Content`
3. 点击 `+`
4. 点击 `Add Other...` → `Add Files...`
5. 选择 `~/Downloads/build-apple/llama.xcframework`
6. 点击 `Open`

### 第三步：配置 Embed 设置

确保 `llama.xcframework` 的 `Embed` 设置为：
- **Do Not Embed**（如果只在模拟器测试）
- 或 **Embed & Sign**（如果要在真机运行）

### 第四步：修改代码

**LibLlama.swift** 已经有 `import llama`，现在应该能正常工作了！

**不需要修改任何代码！** 🎉

### 第五步：编译测试

1. 选择目标设备：iPhone 15 Pro (模拟器)
2. 按 `⌘ + B` 编译
3. 应该成功编译，不再报错 "No such module 'llama'"

---

## 🎯 添加模型文件

现在 llama 依赖已经解决，接下来添加模型：

### 快速测试方案：使用绝对路径

修改 `ChatMateApp.swift`：

```swift
import SwiftUI

@main
struct ChatMateApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(chatViewModel)
                .task {
                    // 使用你下载的模型文件
                    let modelPath = "/Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
                    
                    if FileManager.default.fileExists(atPath: modelPath) {
                        await chatViewModel.initialize(modelPath: modelPath)
                    } else {
                        print("❌ 模型文件不存在：\(modelPath)")
                    }
                }
        }
    }
}
```

**注意**：这种方式只能在模拟器测试，真机需要将模型打包到 App。

---

## 🚀 运行测试

1. **选择模拟器**：iPhone 15 Pro 或 iPhone 16 Pro
2. **运行**：`⌘ + R`
3. **观察控制台输出**：
   ```
   开始加载模型: /Users/yinlu/Downloads/...
   Using 4 threads
   模型加载成功: Qwen 1.5B Q4_K_M
   ```
4. **测试对话**：
   - 输入："你好"
   - 观察 AI 是否流式回复

---

## 📊 预期效果

### 控制台日志
```
开始加载模型: /Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf
Using 6 threads
Attempting to complete "你好"

n_len = 1024, n_ctx = 2048, n_kv_req = 1026
模型加载成功: qwen2.5-1.5b Q4_K_M
```

### UI 表现
- 用户消息立即显示
- AI 回复逐字出现（流式输出）
- 生成速度：约 3-8 tokens/s（模拟器）

---

## ❗ 常见问题

### 1. 编译错误："Framework not found llama"

**解决**：
- 检查 XCFramework 是否正确添加
- Target → General → Frameworks 中是否有 llama.xcframework
- 清理项目：`⌘ + Shift + K`，然后重新编译

### 2. 运行时崩溃："dyld: Library not loaded"

**解决**：
- 将 Embed 改为 `Embed & Sign`

### 3. 模型加载失败

**解决**：
```swift
// 在 initialize 前添加调试
print("📂 尝试加载模型：\(modelPath)")
print("📋 文件存在：\(FileManager.default.fileExists(atPath: modelPath))")

let fileSize = try? FileManager.default.attributesOfItem(atPath: modelPath)[.size] as? Int64
print("📏 文件大小：\(fileSize ?? 0) bytes")
```

### 4. Metal 错误

如果看到 Metal 相关错误，这是正常的（模拟器不支持 Metal）。
代码会自动降级到 CPU 模式。

---

## 🎉 完成！

现在你的 ChatMate 应用：
- ✅ 使用官方预编译的 llama.xcframework
- ✅ 可以正常编译
- ✅ 能够加载 GGUF 模型
- ✅ 支持流式输出
- ✅ 完全离线运行

开始测试吧！有任何问题随时说。💪
