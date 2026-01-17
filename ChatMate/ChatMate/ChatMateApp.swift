//
//  ChatMateApp.swift
//  ChatMate
//
//  Created by ringlu on 2026/1/17.
//

import SwiftUI

@main
struct ChatMateApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(chatViewModel)
                .task {
                    await loadModel()
                }
        }
    }
    
    /// 加载模型（兼容模拟器和真机）
    private func loadModel() async {
        let modelName = "qwen2.5-1.5b-instruct-q4_k_m"
        
        // 优先级 1：从 Bundle 中读取（真机 + 模拟器）
        if let bundlePath = Bundle.main.path(forResource: modelName, ofType: "gguf") {
            print("✅ 从 App Bundle 加载模型: \(bundlePath)")
            let fileSize = try? FileManager.default.attributesOfItem(atPath: bundlePath)[.size] as? Int64
            print("📊 模型大小: \(formatBytes(fileSize ?? 0))")
            await chatViewModel.initialize(modelPath: bundlePath)
            return
        }
        
        // 优先级 2：从 Documents 目录读取（用户下载的模型）
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Models")
            .appendingPathComponent("\(modelName).gguf")
        
        if FileManager.default.fileExists(atPath: documentsPath.path) {
            print("✅ 从 Documents 加载模型: \(documentsPath.path)")
            await chatViewModel.initialize(modelPath: documentsPath.path)
            return
        }
        
        // 优先级 3：从绝对路径读取（仅模拟器开发测试）
        #if targetEnvironment(simulator)
        let devPath = "/Users/yinlu/Downloads/ChatMate-Models/\(modelName).gguf"
        if FileManager.default.fileExists(atPath: devPath) {
            print("⚠️ 从开发路径加载模型（仅模拟器）: \(devPath)")
            await chatViewModel.initialize(modelPath: devPath)
            return
        }
        #endif
        
        // 都找不到
        await MainActor.run {
            chatViewModel.errorMessage = """
            找不到模型文件！
            
            请确保：
            1. 已将模型添加到 Xcode 项目
            2. 在 Build Phases → Copy Bundle Resources 中包含了 .gguf 文件
            3. 或者下载模型到 Documents/Models/ 目录
            """
        }
        
        print("❌ 找不到模型文件")
        print("已检查的路径:")
        print("  1. Bundle: \(Bundle.main.bundlePath)")
        print("  2. Documents: \(documentsPath.path)")
        #if targetEnvironment(simulator)
        print("  3. 开发路径: /Users/yinlu/Downloads/ChatMate-Models/")
        #endif
    }
    
    /// 格式化字节大小
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
