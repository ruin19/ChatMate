//
//  ChatView.swift
//  ChatMate
//
//  主聊天界面
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            // 打字指示器
                            if viewModel.isGenerating {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom()
                    }
                }
                
                Divider()
                
                // 输入栏
                InputBarView(
                    text: $viewModel.inputText,
                    isDisabled: viewModel.isGenerating,
                    onSend: {
                        viewModel.sendMessage()
                        scrollToBottom()
                    }
                )
            }
            .navigationTitle("ChatMate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.clearMessages) {
                            Label("清空对话", systemImage: "trash")
                        }
                        
                        if viewModel.isGenerating {
                            Button(action: viewModel.stopGeneration) {
                                Label("停止生成", systemImage: "stop.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func scrollToBottom() {
        withAnimation {
            if viewModel.isGenerating {
                scrollProxy?.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

/// 打字指示器
struct TypingIndicatorView: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            Text("正在思考")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(repeating: ".", count: dotCount))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)
        }
        .padding(.horizontal)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel())
}
