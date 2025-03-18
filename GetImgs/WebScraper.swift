//
//  WebScraper.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//
//  该文件提供网页解析功能，从指定 URL 抓取所有图片链接。

import Foundation
import SwiftSoup

struct WebScraper {
    /// 从网页抓取所有图片 URL
    /// - Parameters:
    ///   - url: 目标网页的 URL
    ///   - completion: 异步回调，返回图片 URL 数组（如果解析失败，则返回 `nil`）
    static func fetchImageURLs(from url: URL, completion: @escaping ([URL]?) -> Void) {
        var request = URLRequest(url: url)
        /// 设置 `User-Agent`，模拟真实浏览器，避免被网站屏蔽
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36",
                         forHTTPHeaderField: "User-Agent")

        /// 发送 HTTP 请求获取网页 HTML 内容
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, let html = String(data: data, encoding: .utf8), error == nil else {
                completion(nil) // 如果请求失败或 HTML 解析失败，返回 nil
                return
            }

            do {
                /// 解析 HTML 文档
                let document = try SwiftSoup.parse(html)
                /// 获取所有 `<img>` 标签
                let imgElements = try document.select("img").array()
                /// 提取 `src` 属性，并转换为绝对 URL
                let imgUrls = imgElements.compactMap { element -> URL? in
                    if let src = try? element.attr("src"), let imgUrl = URL(string: src, relativeTo: url)?.absoluteURL {
                        return imgUrl
                    }
                    return nil
                }
                completion(imgUrls) // 返回提取的图片 URL
            } catch {
                completion(nil) // HTML 解析失败，返回 nil
            }
        }.resume() // 启动请求
    }
}
