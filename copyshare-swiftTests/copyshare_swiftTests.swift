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

    @Test func put() async {
        // TODO: Implement an environment variable to hold the base url.
        let copyShare = CopyShare.init(baseURL: "https://example.org/")
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
}
