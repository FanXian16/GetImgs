//
//  ImageDownloader.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageDownloader {
    static func downloadAndConvertImage(from url: URL, to folder: URL, completion: @escaping () -> Void) {
        let filename = url.lastPathComponent
        let originalPath = folder.appendingPathComponent(filename)
        let heicPath = folder.appendingPathComponent(filename).deletingPathExtension().appendingPathExtension("heic")

        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                completion()
                return
            }

            do {
                try FileManager.default.moveItem(at: localURL, to: originalPath)

                if isValidImage(originalPath) {
                    convertToHEIC(from: originalPath, to: heicPath) {
                        try? FileManager.default.removeItem(at: originalPath)
                        completion()
                    }
                } else {
                    try? FileManager.default.removeItem(at: originalPath)
                    completion()
                }
            } catch {
                completion()
            }
        }.resume()
    }

    private static func isValidImage(_ path: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(path as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return false
        }
        return width >= 600 && height >= 800
    }

    private static func convertToHEIC(from source: URL, to destination: URL, completion: @escaping () -> Void) {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            completion()
            return
        }

        guard let imageDestination = CGImageDestinationCreateWithURL(destination as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            completion()
            return
        }

        CGImageDestinationAddImage(imageDestination, image, nil)
        if CGImageDestinationFinalize(imageDestination) {
            completion()
        } else {
            completion()
        }
    }
}
