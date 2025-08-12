//
//  copyshare_swift.swift
//  copyshare-swift
//
//  Created by Chloe Surett on 8/11/25.
//

import Foundation

public enum CopyShareChecksums: String {
    case no = ""
    case md5 = "md5"
    case sha256 = "sha256"
    case b2 = "b2"
    case b2s = "b2s"
}

public enum CopyShareUploadAccepts: String {
    case json = "json"
    case url = "url"
    case length = ""
}

public class CopyShare {
    public var baseURL: URL
    public var session: URLSession
    public init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.init(configuration: .default)
        // Not discretionary by default because user files should be uploaded ASAP.
        self.session.configuration.isDiscretionary = false
    }
    
    public func buildBaseRequest(path: String) throws -> URLRequest {
        guard let requestURL = URLComponents(url: URL(string: path, relativeTo: self.baseURL)!, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        return URLRequest(url: requestURL.url!)
    }
    
    // TODO: Add upload compression option
    public func buildUploadRequest(path: String, accepts: CopyShareUploadAccepts = .json, rand: Int? = nil, checksum: CopyShareChecksums? = nil, lifetime: UInt128? = nil) throws -> URLRequest {
        var request = try buildBaseRequest(path: path)
        request.setValue(accepts.rawValue, forHTTPHeaderField: "Accept")
        if rand != nil {
            // Request a random file name for upload.
            request.setValue(String(rand!), forHTTPHeaderField: "Rand")
        }
        if checksum != nil {
            request.setValue(checksum?.rawValue, forHTTPHeaderField: "CK")
        }
        if lifetime != nil {
            request.setValue(String(lifetime!), forHTTPHeaderField: "Life")
        }
        return request
    }
    
    /// Upload a file using the PUT HTTP method.
    ///
    /// see buildUploadRequest for more info on arguments.
    public func putFile(localPath: URL, remotePath: String, accepts: CopyShareUploadAccepts = .json, rand: Int? = nil, checksum: CopyShareChecksums? = nil, lifetime: UInt128? = nil) async throws -> (String?, Error?)
    {
        var request: URLRequest
        do {
            request = try buildUploadRequest(path: remotePath, accepts: accepts, rand: rand, checksum: checksum, lifetime: lifetime)
        } catch {
            return (nil, error)
        }
        request.httpMethod = "PUT"
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
