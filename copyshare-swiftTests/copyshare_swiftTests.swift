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

    @Test func put() {
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
            try copyShare.putFile(localPath: fileURL, remotePath: testPath)
        } catch {
            print("Failed to upload")
        }
        // Sleep so that the task can finish
        // TODO: Make it so the upload can be awaited on 
        sleep(30)
    }

}
