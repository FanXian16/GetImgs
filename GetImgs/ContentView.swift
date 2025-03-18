import SwiftUI

/// `ContentView` 是主视图，允许用户输入网址，并抓取和下载该网页上的图片。
struct ContentView: View {
    /// 用户输入的网址
    @State private var urlString: String = ""
    /// 是否正在加载（防止重复点击）
    @State private var isLoading: Bool = false
    /// 图片下载进度，范围 0.0 - 1.0
    @State private var downloadProgress: Double = 0.0
    /// 存储已下载图片的本地路径
    @State private var imagePaths: [URL] = []

    var body: some View {
        VStack {
            /// 文本输入框，用户输入要抓取图片的网页地址
            TextField("Enter website URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            /// 按钮，点击后开始抓取网页上的图片
            Button("Fetch and Save Images") {
                startFetching()
            }
            .padding()
            .disabled(isLoading || urlString.isEmpty) // 当 `isLoading` 为 true 或 `urlString` 为空时禁用按钮

            /// 如果正在加载，显示进度条
            if isLoading {
                ProgressView(value: downloadProgress, total: 1.0)
                    .padding()
            }

            /// 滚动视图，显示已下载的图片
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(imagePaths, id: \.self) { imagePath in
                        if let nsImage = NSImage(contentsOf: imagePath) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }

    /// 开始抓取网页中的图片并下载
    private func startFetching() {
        /// 确保输入的字符串可以转换为 URL
        guard let url = URL(string: urlString) else { return }
        isLoading = true // 设置加载状态
        downloadProgress = 0.0 // 重置进度条

        /// 使用 `WebScraper` 解析网页，提取所有图片链接
        WebScraper.fetchImageURLs(from: url) { imageUrls in
            guard let imageUrls = imageUrls else {
                isLoading = false
                return
            }

            /// 创建下载文件夹（以网页标题命名）
            FileManagerHelper.createDownloadFolder(for: url) { folderPath in
                guard let folderPath = folderPath else {
                    isLoading = false
                    return
                }

                let totalImages = imageUrls.count
                var completedImages = 0

                /// 遍历所有图片链接，依次下载
                for imageUrl in imageUrls {
                    ImageDownloader.downloadAndConvertImage(from: imageUrl, to: folderPath) {
                        completedImages += 1
                        downloadProgress = Double(completedImages) / Double(totalImages) // 更新进度条

                        /// 当所有图片下载完成时，更新 UI
                        if completedImages == totalImages {
                            isLoading = false
                            imagePaths = FileManagerHelper.getDownloadedImages(from: folderPath)
                        }
                    }
                }
            }
        }
    }
}
