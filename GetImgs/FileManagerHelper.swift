//
//  FileManagerHelper.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//

import Foundation

struct FileManagerHelper {
    static func createDownloadFolder(for url: URL, completion: @escaping (URL?) -> Void) {
        fetchPageTitle(from: url) { title in
            let safeTitle = title.replacingOccurrences(of: "[/:*?\"<>|]", with: "-", options: .regularExpression)

            let saveFolder = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent(safeTitle)

            do {
                try FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
                completion(saveFolder)
            } catch {
                completion(nil)
            }
        }
    }

    private static func fetchPageTitle(from url: URL, completion: @escaping (String) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, var html = String(data: data, encoding: .utf8) else {
                completion("DownloadedImages")
                return
            }
            
            // 替换 HTML 实体 &ndash; 和 &#8211; 为普通的短横线 -
            html = html.replacingOccurrences(of: "&#8211;", with: "-")
                       .replacingOccurrences(of: "&ndash;", with: "-")
            
            var title = html.range(of: "<title>(.*?)</title>", options: .regularExpression)
                .flatMap { String(html[$0]).replacingOccurrences(of: "<title>|</title>", with: "", options: .regularExpression) }
                ?? "DownloadedImages"
            
            // 删除文件夹名称中的 " - EVERIA.CLUB"
            title = title.replacingOccurrences(of: " - EVERIA.CLUB", with: "")

            completion(title)
        }
        task.resume()
    }

    static func getDownloadedImages(from folder: URL) -> [URL] {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        return fileURLs.filter { $0.pathExtension.lowercased() == "heic" }
    }
}
