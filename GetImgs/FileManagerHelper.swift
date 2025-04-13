//
//  FileManagerHelper.swift
//  GetImgs
//
//  Created by xian on 2025/3/13.
//
//  该文件提供文件管理相关功能，包括创建下载文件夹、转换 URL 为 HTTPS、获取网页标题，以及获取已下载的图片。

import Foundation

struct FileManagerHelper {
    static func createDownloadFolder(for url: URL, completion: @escaping (URL?) -> Void) {
        let secureURL = convertToSecureURL(url)
        fetchPageTitle(from: secureURL) { title in
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
    
    private static func convertToSecureURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.scheme == "http" {
            components?.scheme = "https"
        }
        return components?.url ?? url
    }
    
    
    private static func fetchPageTitle(from url: URL, completion: @escaping (String) -> Void) {
        let secureURL = convertToSecureURL(url)
        
        let task = URLSession.shared.dataTask(with: secureURL) { data, _, _ in
            guard let data = data, var html = String(data: data, encoding: .utf8) else {
                completion("DownloadedImages")
                return
            }
            
            html = html.replacingOccurrences(of: "&#8211;", with: "-")
                .replacingOccurrences(of: "&ndash;", with: "-")
            
            var title = html.range(of: "<title>(.*?)</title>", options: .regularExpression)
                .flatMap { String(html[$0]).replacingOccurrences(of: "<title>|</title>", with: "", options: .regularExpression) }
            ?? "DownloadedImages"
            
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
