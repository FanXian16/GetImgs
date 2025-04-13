import SwiftUI

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var downloadProgress: Double = 0.0
    @State private var imagePaths: [URL] = []
    
    var body: some View {
        VStack {
            TextField("Enter website URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Fetch and Save Images") {
                startFetching()
            }
            .padding()
            .disabled(isLoading || urlString.isEmpty) // 当 `isLoading` 为 true 或 `urlString` 为空时禁用按钮
            
            if isLoading {
                ProgressView(value: downloadProgress, total: 1.0)
                    .padding()
            }
            
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
    
    private func startFetching() {
        guard let url = URL(string: urlString) else { return }
        isLoading = true
        downloadProgress = 0.0
        
        WebScraper.fetchImageURLs(from: url) { imageUrls in
            guard let imageUrls = imageUrls else {
                isLoading = false
                return
            }
            
            FileManagerHelper.createDownloadFolder(for: url) { folderPath in
                guard let folderPath = folderPath else {
                    isLoading = false
                    return
                }
                
                let totalImages = imageUrls.count
                var completedImages = 0
                
                for imageUrl in imageUrls {
                    ImageDownloader.downloadAndConvertImage(from: imageUrl, to: folderPath) {
                        completedImages += 1
                        downloadProgress = Double(completedImages) / Double(totalImages)
                        
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
