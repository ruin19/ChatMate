# 删除和重新添加 llama.cpp Package 依赖

## 方法一：在 Xcode 界面中删除（最简单）

### 步骤 1：删除现有的 Package 依赖

1. **打开项目**
   ```bash
   open ChatMate/ChatMate.xcodeproj
   ```

2. **找到 Package Dependencies**
   - 在左侧项目导航器中，找到项目文件（蓝色图标）
   - 点击项目名称 `ChatMate`
   - 选择 `PROJECT` 下的 `ChatMate`（不是 TARGETS）
   - 点击顶部的 `Package Dependencies` 标签页

3. **删除 llama.cpp**
   - 在列表中找到 `llama.cpp` 或相关的包
   - 选中它
   - 点击下方的 `-` （减号）按钮
   - 或者直接按 `Delete` 键
   - 确认删除

4. **验证删除成功**
   - Package Dependencies 列表应该为空（或者没有 llama.cpp）
   - 左侧导航器中 `Package Dependencies` 节点应该消失或为空

### 步骤 2：清理缓存（重要！）

在终端中执行以下命令：

```bash
# 清理 Xcode 的 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 清理 SPM 缓存
rm -rf ~/Library/Caches/org.swift.swiftpm/*

# 清理项目的 build 文件夹
cd /Users/yinlu/Documents/mycode/ChatMate
rm -rf ChatMate/ChatMate.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
rm -rf ChatMate/ChatMate.xcodeproj/xcuserdata
```

### 步骤 3：重新添加 Package

1. **在 Xcode 中点击菜单**
   ```
   File → Add Package Dependencies...
   ```

2. **输入正确的 URL**
   ```
   https://github.com/ggerganov/llama.cpp
   ```
   
   **⚠️ 注意：不要添加 `.git` 后缀！**

3. **选择版本策略**
   - Dependency Rule: `Branch`
   - Branch: `master`
   
   或者选择：
   - Dependency Rule: `Up to Next Major Version`
   - Version: `1.0.0`

4. **点击 Add Package**
   - 等待 Xcode 解析（可能需要 1-3 分钟）
   - 你会看到进度条

5. **选择要添加的产品**
   - 在弹出的产品列表中，**只勾选**：
     - ✅ `llama` （必选）
   - **不要勾选**其他的（如果有的话）
   - 点击 `Add Package`

6. **验证添加成功**
   - 左侧导航器中应该出现 `Package Dependencies` 节点
   - 展开后能看到 `llama.cpp`
   - 项目应该开始索引新的依赖

---

## 方法二：手动编辑项目文件（如果方法一失败）

### 步骤 1：关闭 Xcode

**重要**：必须先完全关闭 Xcode！

```bash
# 确保 Xcode 完全关闭
killall Xcode
```

### 步骤 2：删除 Package 相关文件

在终端执行：

```bash
cd /Users/yinlu/Documents/mycode/ChatMate/ChatMate

# 删除 SPM 工作空间数据
rm -rf ChatMate.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# 删除用户数据（包含 Package 配置）
rm -rf ChatMate.xcodeproj/xcuserdata

# 删除 Package 解析文件
rm -f Package.resolved

# 清理系统缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*
```

### 步骤 3：编辑 project.pbxproj 文件

```bash
# 备份原文件
cp ChatMate.xcodeproj/project.pbxproj ChatMate.xcodeproj/project.pbxproj.backup

# 用文本编辑器打开
open -a TextEdit ChatMate.xcodeproj/project.pbxproj
```

在文件中**搜索并删除**包含以下关键词的所有行：
- `llama.cpp`
- `llama`
- `XCRemoteSwiftPackageReference`
- `XCSwiftPackageProductDependency`

**示例**（删除类似这些的内容）：
```xml
/* 删除这种块 */
{
    isa = XCRemoteSwiftPackageReference;
    repositoryURL = "https://github.com/ggerganov/llama.cpp";
    requirement = {
        kind = upToNextMajorVersion;
        minimumVersion = 1.0.0;
    };
};

/* 也删除这种 */
{
    isa = XCSwiftPackageProductDependency;
    package = ...;
    productName = llama;
};
```

**⚠️ 警告**：
- 只删除与 llama 相关的行
- 不要删除其他配置
- 保持 JSON/XML 格式正确（括号匹配）

### 步骤 4：重新打开项目

```bash
open ChatMate.xcodeproj
```

然后按照**方法一的步骤 3**重新添加 Package。

---

## 方法三：使用命令行工具（最彻底）

### 完整清理脚本

创建并运行清理脚本：

```bash
#!/bin/bash

echo "🧹 开始清理 llama.cpp Package..."

# 关闭 Xcode
killall Xcode 2>/dev/null

# 进入项目目录
cd /Users/yinlu/Documents/mycode/ChatMate/ChatMate

# 删除 SPM 相关文件
echo "📦 删除 Package 文件..."
rm -rf ChatMate.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
rm -rf ChatMate.xcodeproj/xcuserdata
rm -f Package.resolved

# 清理 Xcode 缓存
echo "🗑️  清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*

# 清理项目构建产物
echo "🧽 清理构建产物..."
rm -rf build/
rm -rf .build/

echo "✅ 清理完成！"
echo "📝 现在请打开 Xcode 重新添加 Package"
echo ""
echo "命令：open ChatMate.xcodeproj"
```

保存为 `clean_packages.sh`，然后运行：

```bash
cd /Users/yinlu/Documents/mycode/ChatMate
chmod +x clean_packages.sh
./clean_packages.sh
```

---

## 常见问题排查

### 问题 1：删除后依然显示错误

**症状**：删除 Package 后，编译时仍然报错 `No such module 'llama'`

**解决**：
```bash
# 完全清理项目
cd /Users/yinlu/Documents/mycode/ChatMate/ChatMate
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 重新打开
open ChatMate.xcodeproj
```

### 问题 2：添加 Package 时一直卡住

**症状**：点击 Add Package 后进度条不动

**解决**：
1. 检查网络连接（llama.cpp 仓库约 4GB）
2. 尝试使用镜像：
   ```
   # 如果 GitHub 访问慢，可以先手动克隆
   cd ~/Downloads
   git clone https://github.com/ggerganov/llama.cpp.git
   
   # 然后在 Xcode 中：
   # File → Add Local Package...
   # 选择 ~/Downloads/llama.cpp
   ```

### 问题 3：Package 添加后找不到 `llama` 模块

**症状**：Package 添加成功，但 `import llama` 报错

**检查清单**：
1. **验证 Package 产品选择**
   - Project → Package Dependencies
   - 点击 llama.cpp 包
   - 右侧应该显示勾选了 `llama` 产品

2. **验证 Target 链接**
   - Target `ChatMate` → Build Phases
   - 展开 `Link Binary With Libraries`
   - 应该有 `llama` 库

3. **手动添加链接**（如果没有）
   - Target → General
   - 滚动到 `Frameworks, Libraries, and Embedded Content`
   - 点击 `+`
   - 搜索 `llama`
   - 添加它

### 问题 4：编译时报错 `Package.swift` 不存在

**原因**：llama.cpp 的 Package.swift 可能在子目录

**解决**：
```bash
# 手动检查
cd ~/Downloads
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
ls -la Package.swift

# 如果存在，在 Xcode 中添加本地包
# File → Add Local Package...
# 选择 ~/Downloads/llama.cpp
```

---

## 验证 Package 安装成功

### 检查清单

1. **项目导航器中**
   ```
   ChatMate.xcodeproj
   └── Package Dependencies
       └── llama.cpp
           └── llama
   ```

2. **编译测试**
   ```swift
   // 在任意 Swift 文件顶部添加
   import llama
   
   // 如果没有报错，说明成功
   ```

3. **查看依赖详情**
   - Project → Package Dependencies 标签页
   - 应该显示：
     ```
     Name: llama.cpp
     Location: https://github.com/ggerganov/llama.cpp
     Status: Up to Date
     ```

4. **编译项目**
   ```
   ⌘ + B
   ```
   - 首次编译可能需要 5-10 分钟（编译 C++ 代码）
   - 不应该有关于 llama 的错误

---

## 下一步

清理并重新添加 Package 后：

1. ✅ 确认编译成功
2. ✅ 验证能 `import llama`
3. ✅ 继续按照 `接下来要做的.md` 添加模型文件
4. ✅ 运行测试

祝你成功！🎉
