# iOS 集成 llama.cpp 完整方案

## 方案一：使用 llama.cpp.swift（推荐）

这是目前最成熟的方案，有专门为 iOS 优化的 Swift 封装。

### 集成步骤

#### 1. 添加 llama.cpp.swift 依赖

有两种方式：

**方式 A：使用 Swift Package Manager**
```
1. 在 Xcode 中：File → Add Package Dependencies
2. 输入 URL：https://github.com/ggerganov/llama.cpp
3. 选择分支：master
4. 添加 libllama 和 llama
```

**方式 B：手动集成（更稳定）**
```bash
# 1. 克隆仓库
cd ~/Downloads
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# 2. 编译 iOS 静态库
mkdir build-ios
cd build-ios
cmake .. -DCMAKE_SYSTEM_NAME=iOS \
         -DCMAKE_OSX_ARCHITECTURES="arm64" \
         -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
         -DCMAKE_BUILD_TYPE=Release \
         -DBUILD_SHARED_LIBS=OFF

make -j4

# 3. 生成的静态库位于：
# build-ios/libllama.a
```

#### 2. 添加模型文件到项目

```bash
# 1. 在 Xcode 项目中创建 Resources 文件夹
# 2. 将 GGUF 模型文件拖入该文件夹
# 3. 确保 "Copy items if needed" 被勾选
# 4. 在 Target Membership 中勾选 ChatMate

# 注意：模型文件会增加 App 体积（约 1GB）
```

#### 3. 创建 Bridging Header

由于 llama.cpp 是 C++ 代码，需要通过 Objective-C++ 桥接。

**创建文件：`ChatMate/ChatMate/Bridge/LlamaBridge.h`**
```objc
#ifndef LlamaBridge_h
#define LlamaBridge_h

#import <Foundation/Foundation.h>

@interface LlamaContext : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath;
- (NSString *)generateText:(NSString *)prompt;
- (void)streamText:(NSString *)prompt callback:(void (^)(NSString *))callback;
- (void)cancel;

@end

#endif
```

**创建文件：`ChatMate/ChatMate/Bridge/LlamaBridge.mm`**
```objc
#import "LlamaBridge.h"
#include "llama.h"
#include <vector>
#include <string>

@interface LlamaContext() {
    llama_model *model;
    llama_context *ctx;
    BOOL shouldStop;
}
@end

@implementation LlamaContext

- (instancetype)initWithModelPath:(NSString *)modelPath {
    self = [super init];
    if (self) {
        shouldStop = NO;
        
        // 初始化 llama
        llama_backend_init(false);
        
        // 设置模型参数
        llama_model_params model_params = llama_model_default_params();
        
        // 加载模型
        const char *path = [modelPath UTF8String];
        model = llama_load_model_from_file(path, model_params);
        
        if (!model) {
            NSLog(@"Failed to load model");
            return nil;
        }
        
        // 创建上下文
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = 2048;  // 上下文长度
        ctx_params.n_threads = 4; // 线程数
        
        ctx = llama_new_context_with_model(model, ctx_params);
        
        if (!ctx) {
            NSLog(@"Failed to create context");
            llama_free_model(model);
            return nil;
        }
    }
    return self;
}

- (void)streamText:(NSString *)prompt callback:(void (^)(NSString *))callback {
    shouldStop = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 将 prompt 转换为 tokens
        std::vector<llama_token> tokens_list;
        const char *prompt_cstr = [prompt UTF8String];
        
        // Tokenize
        tokens_list.resize(strlen(prompt_cstr) + 1);
        int n_tokens = llama_tokenize(
            self->ctx,
            prompt_cstr,
            strlen(prompt_cstr),
            tokens_list.data(),
            tokens_list.size(),
            true,
            false
        );
        tokens_list.resize(n_tokens);
        
        // 生成文本
        const int max_tokens = 512;
        
        for (int i = 0; i < max_tokens && !self->shouldStop; i++) {
            // 评估当前 tokens
            if (llama_eval(self->ctx, tokens_list.data(), tokens_list.size(), 0, 4)) {
                NSLog(@"Failed to eval");
                break;
            }
            
            // 采样下一个 token
            llama_token new_token = llama_sample_token(self->ctx, NULL);
            
            // 检查结束
            if (new_token == llama_token_eos(self->ctx)) {
                break;
            }
            
            // 转换 token 为文本
            char buf[128];
            int n = llama_token_to_piece(self->ctx, new_token, buf, sizeof(buf));
            if (n < 0) {
                break;
            }
            
            NSString *token_text = [[NSString alloc] initWithBytes:buf 
                                                           length:n 
                                                         encoding:NSUTF8StringEncoding];
            
            // 回调到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(token_text);
            });
            
            // 添加到 tokens 列表
            tokens_list.clear();
            tokens_list.push_back(new_token);
        }
        
        // 完成回调
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil);
        });
    });
}

- (void)cancel {
    shouldStop = YES;
}

- (void)dealloc {
    if (ctx) {
        llama_free(ctx);
    }
    if (model) {
        llama_free_model(model);
    }
    llama_backend_free();
}

@end
```

#### 4. 配置 Xcode 项目

1. **添加 Bridging Header**
   - Build Settings → Swift Compiler - General
   - Objective-C Bridging Header: `ChatMate/Bridge/LlamaBridge.h`

2. **添加库搜索路径**
   - Build Settings → Library Search Paths
   - 添加：`$(PROJECT_DIR)/libs`

3. **链接静态库**
   - Build Phases → Link Binary With Libraries
   - 添加 `libllama.a`

4. **添加编译标志**
   - Build Settings → Other C++ Flags
   - 添加：`-std=c++17`

#### 5. 修改 LLMService.swift

```swift
import Foundation

@MainActor
class LLMService: ObservableObject {
    @Published var state: LLMServiceState = .idle
    @Published var loadProgress: Double = 0.0
    
    private var llamaContext: LlamaContext?
    private var currentTask: Task<Void, Never>?
    
    /// 加载模型
    func loadModel(path: String) async throws {
        state = .loading
        loadProgress = 0.0
        
        await Task.detached(priority: .userInitiated) {
            // 在后台线程加载模型
            let context = LlamaContext(modelPath: path)
            
            await MainActor.run {
                if context != nil {
                    self.llamaContext = context
                    self.state = .ready
                    self.loadProgress = 1.0
                } else {
                    self.state = .error("模型加载失败")
                }
            }
        }.value
    }
    
    /// 生成回复（流式）
    func generateResponse(for prompt: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            guard let context = self.llamaContext else {
                continuation.yield("错误：模型未加载")
                continuation.finish()
                return
            }
            
            self.state = .generating
            
            context.streamText(prompt) { token in
                if let token = token {
                    continuation.yield(token)
                } else {
                    // 生成完成
                    continuation.finish()
                    Task { @MainActor in
                        self.state = .ready
                    }
                }
            }
        }
    }
    
    /// 取消生成
    func cancelGeneration() {
        llamaContext?.cancel()
        if state == .generating {
            state = .ready
        }
    }
}
```

#### 6. 在 ChatMateApp.swift 中加载模型

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
                    // 获取模型路径
                    if let modelPath = Bundle.main.path(forResource: "qwen2.5-1.5b-instruct-q4_k_m", ofType: "gguf") {
                        await chatViewModel.initialize(modelPath: modelPath)
                    }
                }
        }
    }
}
```

## 方案二：使用 llama.swift（更简单）

这是一个更高层的封装，更容易集成。

### 集成步骤

```bash
# 1. 添加 SPM 依赖
# File → Add Package Dependencies
# URL: https://github.com/ShenghaiWang/llama.swift
```

### 使用示例

```swift
import llama

class LLMService: ObservableObject {
    private var llama: Llama?
    
    func loadModel(path: String) async throws {
        llama = try await Llama(path: path)
    }
    
    func generateResponse(for prompt: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                guard let llama = self.llama else { return }
                
                for try await token in llama.predict(prompt) {
                    continuation.yield(token)
                }
                continuation.finish()
            }
        }
    }
}
```

## 模型文件处理

### 方案 A：内置到 App（简单但体积大）
```
优点：用户体验好，安装即用
缺点：App 体积增加 1GB+，审核可能有问题
```

### 方案 B：首次启动下载（推荐）
```swift
class ModelManager {
    func downloadModel() async throws {
        let url = URL(string: "https://your-server.com/model.gguf")!
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent("model.gguf")
        
        // 使用 URLSession 下载
        let (location, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: location, to: localURL)
    }
}
```

### 方案 C：用户自行导入
```
通过 Files.app 或 Airdrop 导入模型文件
```

## 性能优化建议

1. **量化级别**：使用 Q4_K_M（已选择）
2. **上下文长度**：设置为 2048（避免内存溢出）
3. **线程数**：4-6 个（根据 iPhone 型号调整）
4. **Metal 加速**：编译时启用 `-DLLAMA_METAL=ON`

## 预期性能

| 设备 | 推理速度 | 内存占用 |
|------|----------|----------|
| iPhone 15 Pro | ~10 tokens/s | ~2GB |
| iPhone 14 | ~6 tokens/s | ~2GB |
| iPhone 13 | ~4 tokens/s | ~2GB |

## 下一步操作

1. 选择集成方案（推荐方案一的手动集成）
2. 编译 llama.cpp iOS 静态库
3. 创建 Bridge 文件
4. 修改 LLMService.swift
5. 测试运行

需要我开始执行哪个方案？
