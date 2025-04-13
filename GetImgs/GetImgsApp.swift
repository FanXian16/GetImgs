//
//  GetImgsApp.swift
//  GetImgs
//
//  Created by xian on 2025/3/12.
//
//  该文件是 SwiftUI 应用的入口，定义了 `GetImgsApp` 结构体，
//  并在 `WindowGroup` 中加载 `ContentView` 作为主界面。

import SwiftUI

/// `GetImgsApp` 结构体是该应用的入口点，符合 SwiftUI `App` 协议。
/// `@main` 标记表示此应用的启动入口。
@main
struct GetImgsApp: App {
    /// `body` 属性定义了应用的用户界面。
    /// `WindowGroup` 代表该应用的主窗口，并加载 `ContentView` 作为起始视图。
    var body: some Scene {
        WindowGroup {
            ContentView() // 加载应用的主界面
        }
    }
}
