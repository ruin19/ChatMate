//
//  MessageBubbleView.swift
//  ChatMate
//
//  消息气泡视图
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // 消息内容
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                
                // 时间戳
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(message: Message(
            content: "你好！这是一条用户消息",
            isUser: true
        ))
        
        MessageBubbleView(message: Message(
            content: "你好！我是 AI 助手。很高兴为你服务！",
            isUser: false
        ))
    }
    .padding()
}
