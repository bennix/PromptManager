//
//  promptManagerApp.swift
//  promptManager
//
//  Created by Nelle Rtcai on 2025/7/4.
//

import SwiftUI

@main
struct promptManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale.current)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // 添加菜单命令
            CommandGroup(replacing: .newItem) {
                Button("new_prompt") {
                    // 这里可以添加全局新建提示词的逻辑
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .pasteboard) {
                Button("copy_to_clipboard") {
                    // 这里可以添加全局复制的逻辑
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}
