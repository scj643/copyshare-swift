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
        // Not discretionary by default because user files should be uploaded ASAP.
        self.session.configuration.isDiscretionary = false
    }
    
    /// Upload a file using the PUT HTTP method.
    ///
    /// Returns the response JSON as text or an error if it has failed to upload.
    public func putFile(localPath: URL, remotePath: String) async throws -> (String?, Error?)
    {
        guard let requestURL = URLComponents(url: URL(string: remotePath, relativeTo: self.baseURL)!, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: requestURL.url!)
        request.httpMethod = "PUT"
        // Return a JSON response
        request.setValue("json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await self.session.upload(for: request, fromFile: localPath)
            guard let resp = resp as? HTTPURLResponse,
                                (200...299).contains(resp.statusCode)
            else {
                print ("server error")
                return (nil, URLError(.badServerResponse))
            }
            return (String(data:data, encoding: .utf8), nil)
        } catch let error as URLError {
            return (nil, error)
        }
    }
}
