//
//  CopyShareSwiftTests.swift
//  CopyShareSwiftTests
//
//  Created by Chloe Surett on 8/11/25.
//

import Testing
@testable import copyshare_swift
import Foundation

struct CopyShareSwiftTests {
    // TODO: Implement an environment variable to hold the base url.
    let copyShare = CopyShare.init(baseURL: "https://example.org/")
    
    @Test(arguments: [("/testing/test.txt", false)]) func put(testPath: String, shouldError: Bool) async {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        let testText = "Hello World"
        do {
            try testText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Temp file created: \(fileURL)")
        } catch {
            print("Failed to write tmp file")
        }
        do {
            let (result, error) = try await copyShare.putFile(localPath: fileURL, remotePath: testPath)
            if shouldError == false {
                assert(error == nil, "Failed to upload with error \(String(describing: error))")
            } else {
                assert(error != nil, "Should have errored out")
                print(error ?? "None")
            }
            print(result ?? "None")
        } catch {
            assertionFailure("Upload failed")
        }
    }
    
    @Test func login() async {
        do {
            let (_, error) = try await copyShare.login(username: "test", password: "test")
            assert(error == nil, "Failed to login error \(String(describing: error))")
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
    
    @Test func loginUpload() async {
        await login()
        await put(testPath: "/login_test/test.txt", shouldError: false)
    }
    
    @Test func failedLoginUpload() async {
        await logout()
        await put(testPath: "/login_test/test.txt", shouldError: true)
    }
}
