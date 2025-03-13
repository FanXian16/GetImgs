//
//  WebScraper.swift
//  GetImgs
//
//  Created by 范贤 on 2025/3/13.
//

import Foundation
import SwiftSoup

struct WebScraper {
    static func fetchImageURLs(from url: URL, completion: @escaping ([URL]?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36",
                         forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, let html = String(data: data, encoding: .utf8), error == nil else {
                completion(nil)
                return
            }

            do {
                let document = try SwiftSoup.parse(html)
                let imgElements = try document.select("img").array()
                let imgUrls = imgElements.compactMap { element -> URL? in
                    if let src = try? element.attr("src"), let imgUrl = URL(string: src, relativeTo: url)?.absoluteURL {
                        return imgUrl
                    }
                    return nil
                }
                completion(imgUrls)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
