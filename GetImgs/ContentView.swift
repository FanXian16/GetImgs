import SwiftUI
import SwiftSoup
import ImageIO
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var images: [URL] = []
    @State private var progress: Double = 0.0
    
    let saveFolder = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop")
        .appendingPathComponent("DownloadedImages")
    
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
                ProgressView(value: progress, total: 1.0)
                    .padding()
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(images, id: \.self) { imageUrl in
                        Image(nsImage: NSImage(contentsOf: imageUrl) ?? NSImage())
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                }
            }
            .padding()
        }
        .padding()
        .onAppear(perform: loadLocalImages)
    }
    
    private func fetchImages() {
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else { return }
        
        isLoading = true
        progress = 0.0
        try? FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let html = String(data: data, encoding: .utf8) else {
                isLoading = false
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                do {
                    let document = try SwiftSoup.parse(html)
                    let imgUrls = try document.select("img").compactMap { element in
                        URL(string: try element.attr("src"), relativeTo: url)?.absoluteURL
                    }
                    
                    let group = DispatchGroup()
                    let totalImages = max(imgUrls.count, 1)
                    var completedImages = 0
                    
                    for imgUrl in imgUrls {
                        group.enter()
                        downloadAndConvertImage(from: imgUrl) {
                            completedImages += 1
                            DispatchQueue.main.async {
                                progress = Double(completedImages) / Double(totalImages)
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        isLoading = false
                        loadLocalImages()
                    }
                    
                } catch {
                    isLoading = false
                }
            }
        }.resume()
    }
    
    private func downloadAndConvertImage(from url: URL, completion: @escaping () -> Void) {
        let heicPath = saveFolder.appendingPathComponent(url.lastPathComponent).deletingPathExtension().appendingPathExtension("heic")
        
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                completion()
                return
            }
            
            do {
                try convertToHEIC(from: localURL, to: heicPath)
                DispatchQueue.main.async { loadLocalImages() }
            } catch {
                print("Failed to convert image")
            }
            completion()
        }.resume()
    }
    
    private func convertToHEIC(from source: URL, to destination: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "ImageConversion", code: -1, userInfo: nil)
        }
        
        guard let imageDestination = CGImageDestinationCreateWithURL(destination as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            throw NSError(domain: "ImageConversion", code: -1, userInfo: nil)
        }
        
        CGImageDestinationAddImage(imageDestination, image, nil)
        if !CGImageDestinationFinalize(imageDestination) {
            throw NSError(domain: "ImageConversion", code: -1, userInfo: nil)
        }
    }
    
    private func loadLocalImages() {
        let imageFiles = (try? FileManager.default.contentsOfDirectory(at: saveFolder, includingPropertiesForKeys: nil)) ?? []
        DispatchQueue.main.async {
            images = imageFiles.filter { $0.pathExtension.lowercased() == "heic" }
        }
    }
}
