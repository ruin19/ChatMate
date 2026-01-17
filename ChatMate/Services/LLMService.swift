//
//  LLMService.swift
//  ChatMate
//
//  本地 LLM 推理服务 - 使用 llama.cpp 直接在设备上运行
//

import Foundation
internal import Combine

/// LLM 服务状态
enum LLMServiceState: Equatable {
    case idle
    case loading
    case ready
    case generating
    case error(String)
}

/// LLM 推理服务
@MainActor
class LLMService: ObservableObject {
    @Published var state: LLMServiceState = .idle
    @Published var loadProgress: Double = 0.0
    
    private var llamaContext: LlamaContext?
    private var isGenerating = false
    
    /// 加载模型
    func loadModel(path: String) async throws {
        state = .loading
        loadProgress = 0.0
        
        print("开始加载模型: \(path)")
        
        // 在后台线程加载模型
        let context = try await Task.detached(priority: .userInitiated) {
            try LlamaContext.create_context(path: path)
        }.value
        
        llamaContext = context
        
        // 获取模型信息
        let modelInfo = await context.model_info()
        print("模型加载成功: \(modelInfo)")
        
        state = .ready
        loadProgress = 1.0
    }
    
    /// 生成回复（流式输出）
    func generateResponse(for prompt: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                await self.performGeneration(prompt: prompt, continuation: continuation)
            }
        }
    }
    
    /// 执行实际的生成
    private func performGeneration(prompt: String, continuation: AsyncStream<String>.Continuation) async {
        guard let llamaContext = llamaContext else {
            await MainActor.run {
                continuation.yield("错误：模型未加载")
                continuation.finish()
            }
            return
        }
        
        await MainActor.run {
            state = .generating
            isGenerating = true
        }
        
        // 初始化生成
        await llamaContext.completion_init(text: prompt)
        
        // 流式生成 tokens
        while await !llamaContext.is_done && isGenerating {
            let token = await llamaContext.completion_loop()
            
            await MainActor.run {
                if !token.isEmpty {
                    continuation.yield(token)
                }
            }
        }
        
        // 清理
        await llamaContext.clear()
        
        await MainActor.run {
            continuation.finish()
            state = .ready
            isGenerating = false
        }
    }
    
    /// 取消生成
    func cancelGeneration() {
        isGenerating = false
        if state == .generating {
            state = .ready
        }
    }
}
