//
//  ImageDownloader.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//
//  该文件定义了 `ImageDownloader` 结构体，用于下载图片、检查图片是否符合要求，并转换图片格式为 HEIC。

import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageDownloader {
    /// 下载图片并转换为 HEIC 格式
    /// - Parameters:
    ///   - url: 需要下载的图片 URL
    ///   - folder: 图片保存的目标文件夹
    ///   - completion: 下载和转换完成后的回调
    static func downloadAndConvertImage(from url: URL, to folder: URL, completion: @escaping () -> Void) {
        let secureURL = convertToSecureURL(url) // 确保 URL 使用 HTTPS，避免安全限制
        let filename = secureURL.lastPathComponent // 获取文件名
        let originalPath = folder.appendingPathComponent(filename) // 生成原始图片的保存路径
        let heicPath = folder.appendingPathComponent(filename).deletingPathExtension().appendingPathExtension("heic") // 生成 HEIC 格式的目标路径

        // 创建一个下载任务
        URLSession.shared.downloadTask(with: secureURL) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                completion() // 如果下载失败，则直接调用回调函数
                return
            }

            do {
                try FileManager.default.moveItem(at: localURL, to: originalPath) // 将下载的文件移动到目标文件夹

                // 检查图片是否符合要求（分辨率是否足够）
                if isValidImage(originalPath) {
                    // 转换为 HEIC 格式
                    convertToHEIC(from: originalPath, to: heicPath) {
                        try? FileManager.default.removeItem(at: originalPath) // 删除原始图片，节省存储空间
                        completion()
                    }
                } else {
                    try? FileManager.default.removeItem(at: originalPath) // 如果图片不符合要求，则删除
                    completion()
                }
            } catch {
                completion() // 发生错误时直接结束
            }
        }.resume() // 启动下载任务
    }

    /// 将 HTTP URL 转换为 HTTPS URL，避免 ATS 限制
    /// - Parameter url: 原始 URL
    /// - Returns: 安全的 HTTPS URL
    private static func convertToSecureURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.scheme == "http" {
            components?.scheme = "https"
        }
        return components?.url ?? url
    }

    /// 检查图片是否符合要求
    /// - Parameter path: 图片文件的 URL
    /// - Returns: 是否符合要求（宽度 ≥ 600px 且 高度 ≥ 800px）
    private static func isValidImage(_ path: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(path as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return false
        }
        return width >= 600 && height >= 800
    }

    /// 将图片转换为 HEIC 格式
    /// - Parameters:
    ///   - source: 原始图片的 URL
    ///   - destination: 目标 HEIC 图片的 URL
    ///   - completion: 转换完成后的回调
    private static func convertToHEIC(from source: URL, to destination: URL, completion: @escaping () -> Void) {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            completion() // 如果无法读取图片，则直接结束
            return
        }

        // 创建 HEIC 格式的目标文件
        guard let imageDestination = CGImageDestinationCreateWithURL(destination as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            completion()
            return
        }

        CGImageDestinationAddImage(imageDestination, image, nil) // 添加图片到目标文件
        if CGImageDestinationFinalize(imageDestination) { // 进行转换
            completion()
        } else {
            completion()
        }
    }
}
