import SwiftUI
import SwiftSoup

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var images: [URL] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            TextField("Enter website URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Fetch Images") {
                fetchImages()
            }
            .padding()
            .disabled(isLoading || urlString.isEmpty)
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(images, id: \..self) { imageUrl in
                            AsyncImage(url: imageUrl) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    private func fetchImages() {
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else { return }
        
        isLoading = true
        images.removeAll()
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("Failed to load HTML")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                do {
                    let document = try SwiftSoup.parse(html)
                    let imgElements = try document.select("img").array()

                    let imgUrls = imgElements.compactMap { element -> URL? in
                        if let src = try? element.attr("src"), let imgUrl = URL(string: src, relativeTo: url)?.absoluteURL {
                            return imgUrl
                        }
                        return nil
                    }

                    DispatchQueue.main.async {
                        self.images = imgUrls
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async { self.isLoading = false }
                    print("Error parsing HTML: \(error)")
                }
            }
        }.resume()
    }
}
