//
//  copyshare_swift.swift
//  copyshare-swift
//
//  Created by Chloe Surett on 8/11/25.
//

import Foundation

public class CopyShare {
    public var baseURL: URL
    public var session: URLSession
    public init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.init(configuration: .default)
    }
    
    public func putFile(localPath: URL, remotePath: String) throws
    {
        guard var requestURL = URLComponents(url: URL(string: remotePath, relativeTo: self.baseURL)!, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: requestURL.url!)
        request.httpMethod = "PUT"
        // Return a JSON response
        // TODO: Make this actually return something useful. Right now this only uploads a file.
        request.setValue("json", forHTTPHeaderField: "Accept")
        let task = self.session.uploadTask(with: request, fromFile: localPath) { data, response, error in
            if let error = error {
                print("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print ("server error")
                    return
            }
            let dataString = String(data:data!, encoding: .utf8)
            print("Response \(dataString ?? "None")")
        }
        task.resume()
    }
}
