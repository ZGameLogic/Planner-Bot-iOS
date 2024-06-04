//
//  Cached Image Service.swift
//  Planner Bot
//
//  Created by Benjamin Shabowski on 5/23/24.
//

import SwiftUI

struct CachedImage: View {
    private var cache: NSCache<NSURL, UIImage>
    var url: String
    var loadingView: AnyView?
    
    @State var image: Image?
    
    init(url: String, loadingView: AnyView? = nil) {
        self.cache = NSCache<NSURL, UIImage>()
        self.url = url
        if let cached = cache.object(forKey: URL(string: url)! as NSURL) {
            image = Image(uiImage: cached)
        }
        self.loadingView = loadingView
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                if let loadingView = loadingView {
                    loadingView
                } else {
                    ProgressView()
                }
            }
        }.onAppear(perform: updateImage)
    }
    
    func updateImage() {
        Task {
            let(data, response) = try await URLSession.shared.data(from: URL(string: url)!)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("invalid response code fetching image from url: \(url)")
                return
            }
            let newImage = UIImage(data: data)
            cache.setObject(newImage!, forKey: URL(string: url)! as NSURL)
            image = Image(uiImage: newImage!)
        }
    }
}
