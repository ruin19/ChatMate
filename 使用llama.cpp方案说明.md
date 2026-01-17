# iOS 应用集成 llama.cpp 完整指南

## 当前状态

✅ 已创建 `LibLlama.swift` - llama.cpp Swift 封装层  
✅ 已更新 `LLMService.swift` - 使用本地推理替代 Ollama API  
⏳ 需要添加 llama.cpp 依赖  
⏳ 需要添加模型文件到项目

## 步骤 1：添加 llama.cpp Package 依赖

### 在 Xcode 中操作：

1. **打开项目**
   ```
   打开 ChatMate/ChatMate.xcodeproj
   ```

2. **添加 Package**
   - 点击菜单：`File` → `Add Package Dependencies...`
   - 在搜索框中输入：`https://github.com/ggerganov/llama.cpp`
   - 点击 `Add Package`
   - 等待加载（可能需要几分钟）

3. **选择 Products**
   - 在弹出的产品选择界面中，勾选：
     - ✅ `llama` (必选)
   - 点击 `Add Package`

4. **验证**
   - 在项目导航器中，展开 `Package Dependencies`
   - 应该能看到 `llama.cpp` 包

### 常见问题：

如果添加 Package 失败，可以尝试：

**方法 A：手动编辑 Package**
1. 关闭 Xcode
2. 编辑 `ChatMate.xcodeproj/project.pbxproj`
3. 在文件末尾的 `packageReferences` 部分添加：
```xml
{
    isa = XCRemoteSwiftPackageReference;
    repositoryURL = "https://github.com/ggerganov/llama.cpp";
    requirement = {
        kind = upToNextMajorVersion;
        minimumVersion = 1.0.0;
    };
}
```

**方法 B：使用 CocoaPods**（更复杂，不推荐）

**方法 C：使用官方预编译框架**（最稳定）
1. 下载：https://github.com/ggml-org/llama.cpp/releases
2. 解压 `llama-xxx-xcframework.zip`
3. 将 `llama.xcframework` 拖入 Xcode 项目
4. 在 Target → General → Frameworks 中添加

## 步骤 2：添加模型文件

你已经下载了模型：`~/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf` (1.0GB)

### 方式 A：打包到 App Bundle（简单，但 App 体积大）

1. **在 Xcode 中创建资源文件夹**
   - 右键点击 `ChatMate/ChatMate` 文件夹
   - 选择 `New Group`
   - 命名为 `Resources`

2. **添加模型文件**
   - 将 `qwen2.5-1.5b-instruct-q4_k_m.gguf` 拖入 `Resources` 文件夹
   - 确保勾选：
     - ✅ Copy items if needed
     - ✅ ChatMate (Target)

3. **更新代码以使用 Bundle 中的模型**

```swift
// ChatMateApp.swift
@main
struct ChatMateApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(chatViewModel)
                .task {
                    // 从 Bundle 中加载模型
                    if let modelPath = Bundle.main.path(
                        forResource: "qwen2.5-1.5b-instruct-q4_k_m",
                        ofType: "gguf"
                    ) {
                        await chatViewModel.initialize(modelPath: modelPath)
                    } else {
                        print("无法找到模型文件")
                    }
                }
        }
    }
}
```

**优点**：用户安装即可使用，无需额外操作  
**缺点**：App 体积增加 1GB，可能影响 App Store 审核和下载

### 方式 B：首次启动时下载（推荐）

1. **创建 ModelDownloader.swift**

```swift
import Foundation

class ModelDownloader: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var error: String?
    
    private let modelURL = "https://your-server.com/qwen2.5-1.5b-instruct-q4_k_m.gguf"
    private let modelName = "qwen2.5-1.5b-instruct-q4_k_m.gguf"
    
    func getModelPath() -> String? {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let modelPath = documentsPath.appendingPathComponent(modelName)
        
        if FileManager.default.fileExists(atPath: modelPath.path) {
            return modelPath.path
        }
        return nil
    }
    
    func downloadModel() async throws -> String {
        guard let url = URL(string: modelURL) else {
            throw NSError(domain: "ModelDownloader", code: -1)
        }
        
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let localURL = documentsPath.appendingPathComponent(modelName)
        
        await MainActor.run {
            isDownloading = true
        }
        
        let (location, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: location, to: localURL)
        
        await MainActor.run {
            isDownloading = false
            downloadProgress = 1.0
        }
        
        return localURL.path
    }
}
```

2. **创建下载界面**

```swift
struct ModelDownloadView: View {
    @ObservedObject var downloader: ModelDownloader
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("首次启动需要下载 AI 模型")
                .font(.headline)
            
            Text("大小：约 1GB")
                .foregroundColor(.secondary)
            
            if downloader.isDownloading {
                ProgressView(value: downloader.downloadProgress)
                Text("\(Int(downloader.downloadProgress * 100))%")
            } else {
                Button("开始下载") {
                    Task {
                        do {
                            let path = try await downloader.downloadModel()
                            isPresented = false
                        } catch {
                            downloader.error = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            if let error = downloader.error {
                Text("错误: \(error)")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
```

### 方式 C：用户手动导入（最灵活）

1. **支持文件导入**

```swift
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showFilePicker = false
    @State private var modelPath: String?
    
    var body: some View {
        VStack {
            if modelPath == nil {
                Button("选择模型文件") {
                    showFilePicker = true
                }
            } else {
                ChatView()
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "gguf")!]
        ) { result in
            switch result {
            case .success(let url):
                // 复制文件到 App 的 Documents 目录
                copyModelFile(from: url)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func copyModelFile(from url: URL) {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let destURL = documentsPath.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: url, to: destURL)
            modelPath = destURL.path
        } catch {
            print("Failed to copy model: \(error)")
        }
    }
}
```

用户可以通过：
- AirDrop 发送模型文件到手机
- 通过 Files.app 导入
- 通过 iTunes 文件共享

## 步骤 3：编译和测试

### 编译步骤：

1. **选择目标设备**
   - 在 Xcode 顶部工具栏，选择一个 iOS 设备或模拟器
   - 推荐：使用真机（模拟器会强制 CPU 模式，速度较慢）

2. **编译项目**
   - 快捷键：`⌘ + B`
   - 或点击菜单：`Product` → `Build`

3. **解决编译错误**（如果有）
   - `import llama` 错误：说明 Package 未正确添加
   - 模型文件找不到：检查 Bundle Resources

4. **运行**
   - 快捷键：`⌘ + R`
   - 或点击左上角的 Play 按钮

### 预期效果：

1. **首次启动**
   - 显示"加载模型中..."（3-10秒，取决于设备）
   - 日志输出：
     ```
     开始加载模型: /path/to/model.gguf
     Using 4 threads
     模型加载成功: Qwen 1.5B Q4_K_M
     ```

2. **对话测试**
   - 输入："你好"
   - AI 应该逐字回复（流式输出）
   - 响应速度：
     - iPhone 15 Pro: ~10 tokens/s
     - iPhone 13: ~4 tokens/s

3. **性能监控**
   - 在 Xcode 中查看：
     - CPU 使用率：60-90%
     - 内存使用：~2GB
     - GPU（如果启用 Metal）

## 步骤 4：性能优化

### 调整参数：

在 `LibLlama.swift` 的 `create_context` 方法中：

```swift
// 减少上下文长度（节省内存）
ctx_params.n_ctx = 1024  // 默认是 2048

// 调整线程数（提升速度）
let n_threads = 6  // 根据设备调整

// 启用 Metal 加速（如果支持）
model_params.n_gpu_layers = 99  // 使用 GPU
```

### 优化建议：

1. **减少响应长度**
   ```swift
   llamaContext.n_len = 512  // 默认 1024
   ```

2. **调整采样温度**
   ```swift
   llama_sampler_chain_add(self.sampling, llama_sampler_init_temp(0.5))  // 更确定性
   ```

3. **使用更小的模型**
   - Q4_K_M (1GB) ✅ 当前
   - Q3_K_M (800MB) - 更快但质量稍降
   - Q2_K (600MB) - 最快但质量明显下降

## 常见问题排查

### 1. llama.cpp Package 添加失败

**错误信息**：`Package.swift doesn't exist`

**解决**：
- llama.cpp 的 Package.swift 在仓库根目录
- 确保使用最新版本的 Xcode
- 尝试清理缓存：`⌘ + Shift + K`

### 2. 编译错误：`No such module 'llama'`

**解决**：
- 检查 Package Dependencies 是否正确添加
- 检查 Target → Build Phases → Link Binary 中是否有 libllama
- 清理派生数据：`⌘ + Shift + Option + K`

### 3. 运行时崩溃：`Could not load model`

**原因**：
- 模型文件路径不正确
- 模型文件损坏
- GGUF 版本不兼容

**解决**：
- 检查模型文件是否存在：`print(modelPath)`
- 重新下载模型
- 确保使用最新的 GGUF 格式

### 4. 运行时报错：`n_kv_req > n_ctx`

**原因**：输入的 prompt 太长，超过了上下文窗口

**解决**：
- 增加 `n_ctx` 值（会增加内存使用）
- 减少 prompt 长度
- 实现对话历史截断

### 5. 生成速度太慢

**优化**：
- 使用真机测试（模拟器没有 Metal 加速）
- 启用 GPU 层：`n_gpu_layers = 99`
- 使用更小的量化模型
- 减少线程数以避免上下文切换开销

## 下一步

完成上述步骤后，你的 ChatMate 应用将：

✅ 完全离线运行  
✅ 直接在 iPhone 上推理  
✅ 支持流式输出  
✅ 无需外部服务器  

建议测试场景：
1. 简单对话："你好"、"介绍一下自己"
2. 代码生成："写一个 Swift 函数计算斐波那契数列"
3. 中文理解："解释一下什么是人工智能"
4. 长文本生成："写一篇关于秋天的小诗"

祝你成功！🎉
