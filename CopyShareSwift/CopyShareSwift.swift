//
//  CopyShareSwift.swift
//  CopyShareSwift
//
//  Created by Chloe Surett on 8/11/25.
//

import Foundation

/// Avaliable list of checksum types that can be returned.
public enum CopypartyChecksums: String {
    case no = ""
    case md5 = "md5"
    case sha256 = "sha256"
    case b2 = "b2"
    case b2s = "b2s"
}

/// Responses that should be given when uploading.
public enum CopypartyUploadAccepts: String {
    case json = "json"
    case url = "url"
    case length = ""
}

public enum CopypartyFormActions: String {
    case login = "login"
    case logout = "logout"
    // TODO: Implement other methods from https://github.com/9001/copyparty/blob/hovudstraum/copyparty/httpcli.py#L2490
}

// from https://theswiftdev.com/easy-multipart-file-upload-for-swift/
// Allow Data to have strings appeneded.
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
public struct CopypartyMultipartFormRequest {
    private var boundary: String
    private var body: Data
    private let seperator: String = "\r\n"
    
    /// Create a multipart form request.
    /// - Parameter action: The function to use on the multipart upload
    public init(action: CopypartyFormActions) {
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
    
    /// Add a key value pair to the form
    /// - Parameters:
    ///   - key: Key to use
    ///   - value: Value to use
    public mutating func add(key: String, value: String) {
        appendBoundrySeperator()
        body.append(disposition(key) + seperator)
        appendSeperator()
        body.append(value + seperator)
    }
    
    public var httpContentTypeHeaderValue: String {
            "multipart/form-data; boundary=\(boundary)"
    }
    
    /// Formatted http body to put in the request body.
    public var httpBody: Data {
        var httpBodyData = body
        httpBodyData.append("--\(boundary)--\(seperator)")
        return httpBodyData
    }
}

public class CopyShare {
    public var baseURL: URL
    public var session: URLSession
    /// Create a CopyShare instance.
    /// Avoid making multiple instances if you want to use background uploads.
    /// - Parameter baseURL: The base url to perform actions on.
    public init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.init(configuration: .default)
        // Not discretionary by default because user files should be uploaded ASAP.
        self.session.configuration.isDiscretionary = false
        self.session.configuration.httpShouldSetCookies = true
    }
    
    /// Login to the copyparty server at the baseURL
    /// - Parameters:
    ///   - username: Optional username. Not used if usernames is unset in the copyparty config. This is not autodetected.
    ///   - password: Required password
    /// - Returns: response as a string and error if any.
    public func login(username: String?, password: String) async throws -> (String?, Error?) {
        var request = URLRequest(url: self.baseURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("json", forHTTPHeaderField: "Accept")
        var formRequest = CopypartyMultipartFormRequest(action: .login)
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
    
    /// Logout from copyparty at the baseURL
    /// - Returns: Response and error
    public func logout() async throws -> (String?, Error?) {
        var request = URLRequest(url: self.baseURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        let formRequest = CopypartyMultipartFormRequest(action: .logout)
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
    /// Build a URLRequest using the provided arguments
    /// - Parameters:
    ///   - path: path relative to the baseURL
    ///   - accepts: UploadAccepts format to use. Default is json
    ///   - rand: If not nil give the uploaded file a random name with the given umber of characters
    ///   - checksum: Which type of checksum to return
    ///   - lifetime: How long the file should stay uploaded. Must have the `lifetime` volflag set in Copyparty
    /// - Returns: Built `URLRequest`
    public func buildUploadRequest(path: String, accepts: CopypartyUploadAccepts = .json, rand: Int? = nil, checksum: CopypartyChecksums? = nil, lifetime: UInt128? = nil) throws -> URLRequest {
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
    /// see `buildUploadRequest` for more info on arguments.
    /// Returns the response or an error. If it's an HTTP error the code is also returned as statusCode on the userInfo
    public func putFile(localPath: URL, remotePath: String, accepts: CopypartyUploadAccepts = .json, rand: Int? = nil, checksum: CopypartyChecksums? = nil, lifetime: UInt128? = nil) async throws -> (String?, Error?)
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
                return (nil, URLError(.badServerResponse, userInfo: ["statusCode": resp?.statusCode ?? -1]))
            }
            return (String(data:data, encoding: .utf8), nil)
        } catch let error as URLError {
            return (nil, error)
        }
    }
}
