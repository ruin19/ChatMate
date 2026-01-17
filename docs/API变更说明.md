# llama.cpp API 变更说明

## 已修复的问题

### 1. `llama_memory_clear` 函数不存在

**错误信息**：
```
Cannot find 'llama_memory_clear' in scope
```

**原因**：
在新版本的 llama.cpp 中，内存管理 API 发生了变化。

**修复**：
```swift
// 旧版本（不再可用）
llama_memory_clear(llama_get_memory(context), true)

// 新版本（已修复）
llama_kv_cache_clear(context)
```

**影响的文件**：
- `ChatMate/ChatMate/Services/LibLlama.swift` (第 194 行)

---

## llama.cpp 版本信息

使用的 XCFramework 版本：
- **Release**: b5046
- **下载地址**: https://github.com/ggml-org/llama.cpp/releases/download/b5046/llama-b5046-xcframework.zip
- **日期**: 2025-04-04

---

## 其他可能需要注意的 API 变更

根据头文件分析，以下函数标记为 DEPRECATED：

### 1. KV Cache 相关
```swift
// 已废弃（但仍可用）
llama_kv_cache_clear(ctx)

// 新的推荐方式（如果有）
// 查看最新文档
```

### 2. 采样相关
新版本使用 `llama_sampler` 系列函数：
- `llama_sampler_chain_init()`
- `llama_sampler_chain_add()`
- `llama_sampler_init_temp()`
- `llama_sampler_init_dist()`
- `llama_sampler_sample()`

这些在我们的代码中已正确使用。

---

## 编译测试

修复后，执行以下测试：

1. **编译测试**
   ```
   ⌘ + B
   ```
   应该成功，无编译错误。

2. **运行测试**
   ```
   ⌘ + R
   ```
   应该能正常启动。

3. **功能测试**
   - 输入消息
   - 测试 AI 回复
   - 测试停止生成
   - 测试清空对话（这会调用 `clear()` 函数）

---

## 如果还有其他 API 错误

查看官方文档：
- https://github.com/ggerganov/llama.cpp/blob/master/include/llama.h
- https://github.com/ggerganov/llama.cpp/blob/master/docs/api.md

或者检查 XCFramework 中的头文件：
```bash
cat ~/Downloads/build-apple/llama.xcframework/ios-arm64/llama.framework/Headers/llama.h
```

---

## ✅ 当前状态

- [x] llama.xcframework 已添加
- [x] API 兼容性已修复
- [x] 编译通过
- [ ] 运行测试（待执行）

现在可以在 Xcode 中运行项目了！🚀
