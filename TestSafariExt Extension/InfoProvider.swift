//
//  InfoProvider.swift
//  TestSafariExt Extension
//
//  Created by Yehor Popovych on 05/08/2023.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    public func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }
}

struct PluginInfoProvider {
    struct Manifest: Decodable {
        let icons: [Int: String]
    }
    let name: String
    let scheme: String
    let icon: String
    
    init(bundle: Bundle) throws {
        let name = bundle.infoDictionary?["CFBundleDisplayName"] ?? bundle.infoDictionary?["CFBundleName"]
        self.name = (name as? String) ?? "Unknown Name"
        guard let scheme = bundle.infoDictionary?["WalletURLScheme"] as? String else {
            throw ReqError.infoParsing(error: "WalletURLScheme is empty in Info.plist")
        }
        self.scheme = scheme
        guard let jsonUrl = bundle.url(forResource: "manifest", withExtension: "json") else {
            throw ReqError.infoParsing(error: "mainfest.json is not found")
        }
        let data = try Data(contentsOf: jsonUrl)
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        let maxIcon = manifest.icons.reduce(0) { (prev, cur) in cur.key > prev ? cur.key : prev }
        let maxIconPath = manifest.icons[maxIcon]!
        guard let iconUrl = bundle.url(forResource: maxIconPath, withExtension: "") else {
            throw ReqError.infoParsing(error: "Icon not found: " + maxIconPath)
        }
        let string = try Data(contentsOf: iconUrl).base64EncodedString()
        self.icon = "data:\(iconUrl.mimeType());base64, " + string
    }
}
