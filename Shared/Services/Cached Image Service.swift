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
    let fetchBeforeAppear: Bool?
    let skipNetworkFetch: Bool?
    
    @State var image: Image?
    
    init(url: String, loadingView: AnyView? = nil, fetchBeforeAppear: Bool? = nil, skipNetworkFetch: Bool? = nil) {
        self.cache = NSCache<NSURL, UIImage>()
        self.url = url
        if let cached = cache.object(forKey: URL(string: url)! as NSURL) {
            image = Image(uiImage: cached)
        }
        self.loadingView = loadingView
        self.fetchBeforeAppear = fetchBeforeAppear
        self.skipNetworkFetch = skipNetworkFetch
        if let fetch = fetchBeforeAppear, fetch {
            updateImageSync(url: url)
        }
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
        }.onAppear(perform: {
            if(fetchBeforeAppear == nil || fetchBeforeAppear != nil && !fetchBeforeAppear!){
                if(skipNetworkFetch == nil || skipNetworkFetch != nil && !skipNetworkFetch!){
                    updateImage()
                }
            }
        })
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
    
    func updateImageSync(url: String) {
        guard let url = URL(string: url) else { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        var newImage: UIImage?
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            guard error == nil else {
                print("Error fetching image: \(error!.localizedDescription)")
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Invalid response code fetching image from url: \(url)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            newImage = UIImage(data: data)
        }
        
        task.resume()
        semaphore.wait()
        guard let image = newImage else {
            print("Failed to create image from data")
            return
        }
        
        // Cache and set the image
        cache.setObject(image, forKey: url as NSURL)
        self.image = Image(uiImage: image)
    }
}
