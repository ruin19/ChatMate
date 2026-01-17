//
//  InputBarView.swift
//  ChatMate
//
//  输入栏视图
//

import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 输入框
            TextField("输入消息...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .disabled(isDisabled)
                .focused($isFocused)
                .onSubmit {
                    if !text.isEmpty {
                        sendAndDismissKeyboard()
                    }
                }
            
            // 发送按钮
            Button(action: sendAndDismissKeyboard) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }
    
    /// 发送消息并收起键盘
    private func sendAndDismissKeyboard() {
        guard canSend else { return }
        
        // 先收起键盘
        isFocused = false
        
        // 再发送消息
        onSend()
    }
}

#Preview {
    VStack {
        Spacer()
        InputBarView(text: .constant(""), isDisabled: false) {
            print("发送")
        }
    }
}
