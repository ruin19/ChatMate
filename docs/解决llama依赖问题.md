# 解决 llama.cpp 依赖问题

## 问题原因

llama.cpp 官方仓库（https://github.com/ggerganov/llama.cpp）**没有 Package.swift 文件**，因此不支持 Swift Package Manager。

这就是为什么添加后无法 `import llama` 的原因。

## 解决方案

### 方案一：使用 llama.cpp 的 Swift 封装库（推荐）

有几个第三方库封装了 llama.cpp 并提供 SPM 支持：

#### 选项 1：使用 ShenghaiWang/SwiftLlama

**优点**：
- 官方认可的 Swift 封装
- 支持 SPM
- API 简洁

**缺点**：
- 要求 iOS 18+（我们项目是 iOS 15+）

#### 选项 2：使用 guinmoon/llmfarm_core.swift

这个库支持 iOS 14+，更适合我们！

**在 Xcode 中操作**：

1. **删除现有的 llama.cpp Package**
   - Project → Package Dependencies
   - 删除 llama.cpp

2. **添加新 Package**
   ```
   File → Add Package Dependencies...
   URL: https://github.com/guinmoon/llmfarm_core.swift
   Branch: main
   ```

3. **选择产品**
   - 勾选 `llmfarm_core`

4. **修改代码**
   ```swift
   // 将所有文件中的
   import llama
   
   // 改为
   import llmfarm_core
   ```

---

### 方案二：手动集成 llama.cpp（更灵活，推荐）

由于 llama.cpp 本身不支持 SPM，我们手动编译并集成。

#### 步骤 1：编译 llama.cpp 静态库

在终端执行：

```bash
cd ~/Downloads

# 克隆 llama.cpp（如果还没有）
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# 创建 iOS 构建目录
mkdir -p build-ios
cd build-ios

# 使用 CMake 编译 iOS 静态库
cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES="arm64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLAMA_METAL=ON

# 编译
make -j4

# 编译完成后，静态库位于：
# libllama.a
# libggml.a
```

#### 步骤 2：创建 Bridging Header

不再需要 `import llama`，而是通过 Objective-C 桥接。

**创建文件：ChatMate/ChatMate/Bridge/ChatMate-Bridging-Header.h**

```objc
#ifndef ChatMate_Bridging_Header_h
#define ChatMate_Bridging_Header_h

#import "llama.h"
#import "ggml.h"

#endif
```

#### 步骤 3：配置 Xcode

1. **添加头文件搜索路径**
   - Target → Build Settings
   - 搜索 `Header Search Paths`
   - 添加：`$(PROJECT_DIR)/../llama.cpp`（递归）

2. **添加库搜索路径**
   - Build Settings → Library Search Paths
   - 添加：`$(PROJECT_DIR)/../llama.cpp/build-ios`

3. **链接静态库**
   - Target → Build Phases → Link Binary With Libraries
   - 添加：
     - `libllama.a`
     - `libggml.a`

4. **配置 Bridging Header**
   - Build Settings → Swift Compiler - General
   - Objective-C Bridging Header: `ChatMate/Bridge/ChatMate-Bridging-Header.h`

---

### 方案三：使用预编译的 XCFramework（最简单，强烈推荐！）

llama.cpp 官方提供预编译的 XCFramework！

#### 步骤 1：下载 XCFramework

```bash
cd ~/Downloads

# 下载最新版本（约 10MB）
curl -L -o llama.xcframework.zip \
  "https://github.com/ggml-org/llama.cpp/releases/download/b4014/llama-b4014-bin-macos-arm64.zip"

# 解压
unzip llama.xcframework.zip
```

或者访问：https://github.com/ggml-org/llama.cpp/releases
找到最新的 `llama-xxx-bin-macos-arm64.zip` 下载。

#### 步骤 2：添加到 Xcode 项目

1. **拖入 XCFramework**
   - 在 Finder 中找到解压的 `llama.xcframework`
   - 拖入 Xcode 项目的 `ChatMate/ChatMate` 文件夹
   - 确保勾选：
     - ✅ Copy items if needed
     - ✅ ChatMate (Target)

2. **配置 Framework**
   - Target → General → Frameworks, Libraries, and Embedded Content
   - 找到 `llama.xcframework`
   - 设置为 `Embed & Sign` 或 `Do Not Embed`（根据需要）

3. **修改代码**
   - 不需要 `import llama`
   - 直接使用 C API（通过 Bridging Header）

---

### 方案四：不使用 SPM，直接复制 Swift 文件（最快速）

既然我们已经有了 `LibLlama.swift`，而它只是对 C API 的封装，我们可以：

1. **手动复制 llama.cpp 的头文件和库文件**
2. **不使用 `import llama`**
3. **通过 Bridging Header 直接调用 C API**

#### 快速实现步骤

**1. 下载 llama.cpp 示例项目的 C 库**

```bash
cd ~/Downloads
git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# 编译
make

# 生成的库在项目根目录
```

**2. 创建 Bridge 文件夹结构**

在 Xcode 中：
```
ChatMate/ChatMate/
  ├── Bridge/
  │   ├── ChatMate-Bridging-Header.h
  │   └── include/  (存放 llama.h, ggml.h 等头文件)
```

**3. 修改 LibLlama.swift**

移除 `import llama`，直接使用 C 函数（它们会通过 Bridging Header 自动暴露）。

---

## 我的推荐

**最简单快速的方案：方案四（直接使用 C API）**

我现在就帮你实现这个方案！
