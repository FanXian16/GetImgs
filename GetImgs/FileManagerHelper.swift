//
//  FileManagerHelper.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//

import Foundation

struct FileManagerHelper {
    static func createDownloadFolder(for url: URL, completion: @escaping (URL?) -> Void) {
        let title = url.host ?? "DownloadedImages"
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

    static func getDownloadedImages(from folder: URL) -> [URL] {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        return fileURLs.filter { $0.pathExtension.lowercased() == "heic" }
    }
}
