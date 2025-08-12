//
//  copyshare_swiftTests.swift
//  copyshare-swiftTests
//
//  Created by Chloe Surett on 8/11/25.
//

import Testing
@testable import copyshare_swift
import Foundation

struct copyshare_swiftTests {
    // TODO: Implement an environment variable to hold the base url.
    let copyShare = CopyShare.init(baseURL: "https://example.org/")

    @Test func put() async {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        let testPath = "/testing/test.txt"
        let testText = "Hello World"
        do {
            try testText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Temp file created: \(fileURL)")
        } catch {
            print("Failed to write tmp file")
        }
        do {
            let (result, error) = try await copyShare.putFile(localPath: fileURL, remotePath: testPath)
            assert(error == nil, "Failed to upload with error \(String(describing: error))")
            print(result ?? "None")
        } catch {
            assertionFailure("Upload failed")
        }
    }
    
    @Test func login() async {
        do {
            let (_, error) = try await copyShare.login(username: "test", password: "test")
            assert(error == nil, "Failed to login error \(String(describing: error))")
            // Print out the cookies to visually check if it was set
            assert(HTTPCookieStorage.shared.cookies?.count ?? 0 > 0, "Cookie was not set")
        } catch {
            assertionFailure("Login failed")
        }
    }
    
    @Test func logout() async {
        await login()
        do {
            let (_, error) = try await copyShare.logout()
            assert(error == nil, "Failed to logout error \(String(describing: error))")
            assert(HTTPCookieStorage.shared.cookies?.count ?? 0 == 0, "Cookie was not unset")
        } catch {
            assertionFailure("Logout failed")
        }
    }
}
