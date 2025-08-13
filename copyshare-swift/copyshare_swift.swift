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

public enum CopyShareFormActions: String {
    case login = "login"
    case logout = "logout"
    // TODO: Implement other methods from https://github.com/9001/copyparty/blob/hovudstraum/copyparty/httpcli.py#L2490
}

// from https://theswiftdev.com/easy-multipart-file-upload-for-swift/
/// Allow Data to have strings appeneded.
extension Data {
    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

// Modified from https://theswiftdev.com/easy-multipart-file-upload-for-swift/
public struct CopyPartyMultipartFormRequest {
    private var boundary: String
    private var body: Data
    private let seperator: String = "\r\n"
    
    public init(action: CopyShareFormActions) {
        self.body = .init()
        self.boundary = UUID().uuidString
        self.add(key: "act", value: action.rawValue)
    }
    
    private mutating func appendBoundrySeperator() {
        body.append("--\(boundary)\(seperator)")
    }
    
    private mutating func appendSeperator() {
        body.append(seperator)
    }
    
    private func disposition(_ key: String) -> String {
        return "Content-Disposition: form-data; name=\"\(key)\""
    }
    
    public mutating func add(key: String, value: String) {
        appendBoundrySeperator()
        body.append(disposition(key) + seperator)
        appendSeperator()
        body.append(value + seperator)
    }
    
    public var httpContentTypeHeaderValue: String {
            "multipart/form-data; boundary=\(boundary)"
    }
    
    public var httpBody: Data {
        var httpBodyData = body
        httpBodyData.append("--\(boundary)--\(seperator)")
        return httpBodyData
    }
}

public class CopyShare {
    public var baseURL: URL
    public var session: URLSession
    public init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.init(configuration: .default)
        // Not discretionary by default because user files should be uploaded ASAP.
        self.session.configuration.isDiscretionary = false
        self.session.configuration.httpShouldSetCookies = true
    }
    
    public func login(username: String?, password: String) async throws -> (String?, Error?) {
        var request = URLRequest(url: self.baseURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("json", forHTTPHeaderField: "Accept")
        var formRequest = CopyPartyMultipartFormRequest(action: .login)
        request.setValue(formRequest.httpContentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
        if username != nil {
            formRequest.add(key: "uname", value: username!)
        }
        formRequest.add(key: "cppwd", value: password)
        request.httpBody = formRequest.httpBody
        do {
            let (data, resp) = try await  self.session.data(for: request)
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
    
    public func logout() async throws -> (String?, Error?) {
        var request = URLRequest(url: self.baseURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        let formRequest = CopyPartyMultipartFormRequest(action: .logout)
        request.setValue("json", forHTTPHeaderField: "Accept")
        request.setValue(formRequest.httpContentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = formRequest.httpBody
        do {
            let (data, resp) = try await  self.session.data(for: request)
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
                let resp = resp as? HTTPURLResponse
                return (nil, URLError(.badServerResponse, userInfo: ["statusCode": resp?.statusCode ?? 0]))
            }
            return (String(data:data, encoding: .utf8), nil)
        } catch let error as URLError {
            return (nil, error)
        }
    }
}
