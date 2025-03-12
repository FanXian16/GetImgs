import SwiftUI
import SwiftSoup
import ImageIO
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            TextField("Enter website URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Fetch and Save Images") {
                fetchImages()
            }
            .padding()
            .disabled(isLoading || urlString.isEmpty)

            if isLoading {
                ProgressView()
            }
        }
        .padding()
    }

    private func fetchImages() {
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else { return }

        isLoading = true
        print("🌍 开始爬取: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 网络请求失败: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("❌ HTML 加载失败")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            DispatchQueue.global(qos: .background).async {
                do {
                    let document = try SwiftSoup.parse(html)
                    let title = (try? document.title()) ?? "DownloadedImages"
                    let safeTitle = title.replacingOccurrences(of: "[/:*?\"<>|]", with: "-", options: .regularExpression)

                    print("📂 解析网页标题: \(safeTitle)")

                    let saveFolder = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Desktop")
                        .appendingPathComponent(safeTitle)

                    try? FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
                    print("📁 文件夹创建成功: \(saveFolder.path)")

                    let imgElements = try document.select("img").array()
                    let imgUrls = imgElements.compactMap { element -> URL? in
                        if let src = try? element.attr("src"), let imgUrl = URL(string: src, relativeTo: url)?.absoluteURL {
                            print("🖼 发现图片: \(imgUrl.absoluteString)")
                            return imgUrl
                        }
                        return nil
                    }

                    let group = DispatchGroup()

                    for imgUrl in imgUrls {
                        group.enter()
                        downloadAndConvertImage(from: imgUrl, to: saveFolder) {
                            group.leave()
                        }
                    }

                    group.notify(queue: .main) {
                        print("✅ 所有图片已处理完成！")
                        self.isLoading = false
                    }

                } catch {
                    DispatchQueue.main.async { self.isLoading = false }
                    print("❌ HTML 解析失败: \(error)")
                }
            }
        }.resume()
    }


    private func downloadAndConvertImage(from url: URL, to folder: URL, completion: @escaping () -> Void) {
        let filename = url.lastPathComponent
        let originalPath = folder.appendingPathComponent(filename)
        let heicPath = folder.appendingPathComponent(filename).deletingPathExtension().appendingPathExtension("heic")

        print("⬇️ 开始下载: \(url.absoluteString)")

        URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                print("❌ 下载失败: \(error.localizedDescription)")
                completion()
                return
            }
            guard let localURL = localURL else {
                print("❌ 下载失败，localURL 为空")
                completion()
                return
            }

            do {
                try FileManager.default.moveItem(at: localURL, to: originalPath)
                print("📸 下载完成: \(originalPath.path)")

                // ✅ 读取图片尺寸
                let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
                guard let source = CGImageSourceCreateWithURL(originalPath as CFURL, options as CFDictionary),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                      let width = properties[kCGImagePropertyPixelWidth] as? Int,
                      let height = properties[kCGImagePropertyPixelHeight] as? Int else {
                    print("⚠️ 无法读取图片尺寸，跳过: \(originalPath.lastPathComponent)")
                    try? FileManager.default.removeItem(at: originalPath) // 删除无效图片
                    completion()
                    return
                }

                // ✅ 过滤小图
                if width < 600 || height < 800 {
                    print("🚫 图片太小（\(width)x\(height)），删除: \(originalPath.lastPathComponent)")
                    try? FileManager.default.removeItem(at: originalPath) // 删除过小图片
                    completion()
                    return
                }

                // ✅ 符合尺寸要求，转换为 HEIC
                convertToHEIC(from: originalPath, to: heicPath) {
                    try? FileManager.default.removeItem(at: originalPath)
                    print("🗑 已删除原图片: \(originalPath.path)")
                    completion()
                }
            } catch {
                print("❌ 文件移动失败: \(error)")
                completion()
            }
        }.resume()
    }

    private func convertToHEIC(from source: URL, to destination: URL, completion: @escaping () -> Void) {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("❌ HEIC 转换失败: 无法加载图片")
            completion()
            return
        }

        guard let imageDestination = CGImageDestinationCreateWithURL(destination as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            print("❌ HEIC 转换失败: 无法创建目标文件")
            completion()
            return
        }

        CGImageDestinationAddImage(imageDestination, image, nil)
        if CGImageDestinationFinalize(imageDestination) {
            print("✅ HEIC 转换成功: \(destination.path)")
        } else {
            print("❌ HEIC 转换失败")
        }
        completion()
    }
}
