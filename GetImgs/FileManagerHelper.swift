//
//  FileManagerHelper.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//
//  该文件提供文件管理相关功能，包括创建下载文件夹、转换 URL 为 HTTPS、获取网页标题，以及获取已下载的图片。

import Foundation

struct FileManagerHelper {
    /// 创建下载文件夹，并以网页标题命名
    /// - Parameters:
    ///   - url: 目标网页的 URL
    ///   - completion: 返回创建的文件夹 URL（如果失败则返回 `nil`）
    static func createDownloadFolder(for url: URL, completion: @escaping (URL?) -> Void) {
        let secureURL = convertToSecureURL(url) // 确保 URL 使用 HTTPS
        fetchPageTitle(from: secureURL) { title in
            /// 清理标题，去除不允许的字符（如 /:*?"<>|）
            let safeTitle = title.replacingOccurrences(of: "[/:*?\"<>|]", with: "-", options: .regularExpression)

            /// 目标文件夹路径：用户桌面的 `safeTitle` 文件夹
            let saveFolder = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent(safeTitle)

            do {
                /// 创建文件夹，如果已存在则跳过
                try FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
                completion(saveFolder)
            } catch {
                completion(nil) // 创建失败，返回 `nil`
            }
        }
    }

    /// 将 HTTP URL 转换为 HTTPS，以满足 App Transport Security (ATS) 要求
    /// - Parameter url: 原始 URL
    /// - Returns: 安全的 HTTPS URL
    private static func convertToSecureURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.scheme == "http" {
            components?.scheme = "https"
        }
        return components?.url ?? url
    }

    /// 获取网页标题，用于命名下载文件夹
    /// - Parameters:
    ///   - url: 目标网页的 URL
    ///   - completion: 返回解析出的标题，如果失败，则返回 `"DownloadedImages"`
    private static func fetchPageTitle(from url: URL, completion: @escaping (String) -> Void) {
        let secureURL = convertToSecureURL(url) // 确保 URL 使用 HTTPS

        let task = URLSession.shared.dataTask(with: secureURL) { data, _, _ in
            guard let data = data, var html = String(data: data, encoding: .utf8) else {
                completion("DownloadedImages") // 解析失败，返回默认标题
                return
            }
            
            // 替换 HTML 实体 `&ndash;` 和 `&#8211;` 为普通的短横线 "-"
            html = html.replacingOccurrences(of: "&#8211;", with: "-")
                       .replacingOccurrences(of: "&ndash;", with: "-")
            
            /// 通过正则匹配 `<title>网页标题</title>`
            var title = html.range(of: "<title>(.*?)</title>", options: .regularExpression)
                .flatMap { String(html[$0]).replacingOccurrences(of: "<title>|</title>", with: "", options: .regularExpression) }
                ?? "DownloadedImages"
            
            /// 去掉标题中的 `" - EVERIA.CLUB"`
            title = title.replacingOccurrences(of: " - EVERIA.CLUB", with: "")

            completion(title)
        }
        task.resume()
    }

    /// 获取已下载的 HEIC 图片列表
    /// - Parameter folder: 目标文件夹的 URL
    /// - Returns: 包含 `.heic` 扩展名的文件列表
    static func getDownloadedImages(from folder: URL) -> [URL] {
        /// 获取文件夹内的所有文件
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        /// 过滤出 `.heic` 格式的图片
        return fileURLs.filter { $0.pathExtension.lowercased() == "heic" }
    }
}
