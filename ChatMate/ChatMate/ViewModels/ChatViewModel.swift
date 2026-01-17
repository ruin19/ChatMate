//
//  ChatViewModel.swift
//  ChatMate
//
//  聊天视图模型 - 管理消息列表和 AI 交互
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let llmService: LLMService
    private var currentResponseId: UUID?
    
    init(llmService: LLMService) {
        self.llmService = llmService
    }
    
    convenience init() {
        self.init(llmService: LLMService())
    }
    
    /// 初始化并加载模型
    func initialize(modelPath: String) async {
        do {
            try await llmService.loadModel(path: modelPath)
            
            // 添加欢迎消息
            let welcomeMessage = Message(
                content: "你好！我是 ChatMate，一个运行在你手机上的 AI 助手。我完全离线工作，你的所有对话都保存在本地。有什么我可以帮你的吗？",
                isUser: false
            )
            messages.append(welcomeMessage)
        } catch {
            errorMessage = "模型加载失败: \(error.localizedDescription)"
        }
    }
    
    /// 发送消息
    func sendMessage() {
        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty else { return }
        guard !isGenerating else { return }
        
        // 添加用户消息
        let userMessage = Message(content: userInput, isUser: true)
        messages.append(userMessage)
        
        // 清空输入框
        inputText = ""
        
        // 生成 AI 回复
        Task {
            await generateAIResponse(for: userInput)
        }
    }
    
    /// 生成 AI 回复
    private func generateAIResponse(for prompt: String) async {
        isGenerating = true
        
        // 创建 AI 消息占位符
        let aiMessage = Message(content: "", isUser: false)
        currentResponseId = aiMessage.id
        messages.append(aiMessage)
        
        var fullResponse = ""
        
        // 流式接收 AI 回复
        for await token in llmService.generateResponse(for: prompt) {
            fullResponse += token
            
            // 更新消息内容
            if let index = messages.firstIndex(where: { $0.id == currentResponseId }) {
                messages[index] = Message(
                    id: currentResponseId!,
                    content: fullResponse,
                    isUser: false,
                    timestamp: messages[index].timestamp
                )
            }
        }
        
        isGenerating = false
        currentResponseId = nil
    }
    
    /// 停止生成
    func stopGeneration() {
        llmService.cancelGeneration()
        isGenerating = false
    }
    
    /// 清空对话
    func clearMessages() {
        messages.removeAll()
    }
}
