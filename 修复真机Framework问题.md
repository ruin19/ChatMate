# 修复真机 Framework 崩溃问题

## ❌ 问题分析

**错误信息**：
```
Library not loaded: @rpath/llama.framework/llama
Reason: tried: '.../ChatMate.app/Frameworks/llama.framework/llama' (no such file)
```

**原因**：
- ✅ **模拟器正常**：模拟器可以直接链接 Mac 上的 framework
- ❌ **真机崩溃**：真机需要 framework 被嵌入（embed）到 App Bundle 中

---

## ✅ 解决方案

### 方法 1：在 Xcode 中设置 Embed（推荐）

#### 步骤 1：打开 General 设置

1. 点击左侧项目导航器顶部的蓝色项目图标 `ChatMate`
2. 选择 `TARGETS` → `ChatMate`（不是 PROJECT）
3. 点击顶部的 `General` 标签

#### 步骤 2：找到 Frameworks 部分

向下滚动到 **"Frameworks, Libraries, and Embedded Content"** 部分

#### 步骤 3：检查 llama.xcframework

在列表中找到 `llama.xcframework`，检查右侧的 `Embed` 列：

- ❌ 如果显示 **"Do Not Embed"** → 这就是问题所在！
- ✅ 需要改为 **"Embed & Sign"**

#### 步骤 4：修改为 Embed & Sign

1. 点击 `llama.xcframework` 这一行右侧的下拉菜单
2. 选择 **"Embed & Sign"**
3. 确认修改

#### 步骤 5：重新编译运行

```
⌘ + Shift + K  # 清理构建
⌘ + B          # 重新编译
⌘ + R          # 运行到真机
```

---

### 方法 2：手动检查 Build Phases（备选）

如果方法 1 找不到 llama.xcframework，使用这个方法：

#### 1. 打开 Build Phases

- `TARGETS` → `ChatMate` → `Build Phases` 标签

#### 2. 检查 Link Binary With Libraries

展开 **"Link Binary With Libraries"** 部分：
- ✅ 确认 `llama.xcframework` 在列表中
- 如果没有，点击 `+` 添加

#### 3. 添加 Embed Frameworks Phase

在 Build Phases 中：
1. 点击左上角的 `+` 按钮
2. 选择 **"New Copy Files Phase"**
3. 命名为 `Embed Frameworks`
4. 设置 `Destination` 为 **"Frameworks"**
5. 点击 `+` 添加 `llama.xcframework`
6. 勾选 **"Code Sign On Copy"**

---

### 方法 3：检查 XCFramework 位置（确认文件存在）

验证 XCFramework 是否在正确位置：

```bash
# 检查是否存在
ls -la ~/Downloads/build-apple/llama.xcframework

# 查看结构
tree -L 2 ~/Downloads/build-apple/llama.xcframework
```

---

## 🔍 验证修复

### 1. 检查 Build Settings

确认以下设置正确：

- Target: `ChatMate`
- Build Settings 标签
- 搜索 `Runpath Search Paths`
- 应该包含：
  ```
  @executable_path/Frameworks
  @loader_path/Frameworks
  ```

### 2. 查看编译日志

编译时在控制台搜索 `embed`，应该能看到：
```
EmbedFrameworks /path/to/llama.xcframework
```

### 3. 真机运行

- 连接 iPhone
- `⌘ + R` 运行
- 应该不再崩溃 ✅

---

## 🎯 预期效果

### 修复前（崩溃）
```
Library not loaded: @rpath/llama.framework/llama
```

### 修复后（正常运行）
```
✅ 从 App Bundle 加载模型: /var/containers/Bundle/...
📊 模型大小: 1.0 GB
开始加载模型: ...
模型加载成功: ...
```

---

## 📊 App 体积变化

添加 Embed & Sign 后：

| 组件 | 大小 |
|------|------|
| llama.xcframework | ~300 MB |
| 模型文件 (.gguf) | ~1 GB |
| **总计** | **~1.3 GB** |

---

## ⚠️ 常见问题

### Q1: 为什么模拟器不需要 Embed？

**A**: 模拟器运行在 Mac 上，可以直接访问 DerivedData 中的 framework。真机是独立设备，必须将所有依赖打包进 App。

### Q2: Embed 和 Link 的区别？

**A**: 
- **Link**: 编译时链接，告诉编译器代码在哪里
- **Embed**: 运行时嵌入，将 framework 复制到 App Bundle

两者都需要！

### Q3: 编译后 App 太大怎么办？

**A**: 
1. 使用更小的量化模型（Q2/Q3）
2. 改用"首次下载"方案（不打包模型）
3. 使用 On-Demand Resources（App Store 支持）

---

## 🚀 后续优化

### 减小 App 体积

如果需要发布到 App Store，考虑：

#### 方案 1：不打包模型到 Bundle

只嵌入 framework，模型首次启动时下载：
- App 体积：~300 MB（只有 framework）
- 首次启动需要下载 1GB 模型

#### 方案 2：使用更小的模型

使用 Q2 量化：
- 模型体积：~500 MB
- 精度略降，但仍可用

#### 方案 3：多模型选项

让用户选择：
- 基础模型（500 MB）：快速，精度一般
- 标准模型（1 GB）：平衡
- 高级模型（2 GB）：高精度

---

## 📋 检查清单

在真机上测试前，确认：

- [ ] `llama.xcframework` 在 "Frameworks, Libraries, and Embedded Content"
- [ ] Embed 设置为 **"Embed & Sign"**
- [ ] Build Phases 中有 `Embed Frameworks` 步骤
- [ ] Runpath Search Paths 包含 `@executable_path/Frameworks`
- [ ] 清理并重新编译
- [ ] 在真机上运行测试

---

现在去 Xcode 修改设置吧！主要就是把 `llama.xcframework` 的 Embed 改为 **"Embed & Sign"**。
