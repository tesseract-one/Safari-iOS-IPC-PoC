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

private extension Bundle {
    var tesseract: [String: Any] { get throws {
        guard let anytes = infoDictionary?["Tesseract"] else {
            throw ReqError.infoParsing(error: "Can't find Tesseract in Info.plist")
        }
        guard let tesseract = anytes as? [String: Any] else {
            throw ReqError.infoParsing(error: "Tesseract info is not a dictionary")
        }
        return tesseract
    }}
    
    var appName: String { get throws {
        let name = infoDictionary?["CFBundleDisplayName"] ?? infoDictionary?["CFBundleName"]
        guard let name = name as? String else {
            throw ReqError.infoParsing(error: "Can't find app name")
        }
        return name
    }}
    
    var urlScheme: String { get throws {
        guard let anyscheme = try tesseract["URLScheme"] else {
            throw ReqError.infoParsing(error: "Can't find URLScheme in Info.plist")
        }
        guard let scheme = anyscheme as? String else {
            throw ReqError.infoParsing(error: "URLScheme isn't string")
        }
        return scheme
    }}
    
    var protocols: [String] { get throws {
        guard let anyprotos = try tesseract["SupportedProtocols"] else {
            throw ReqError.infoParsing(
                error: "Can't find SupportedProtocols in Info.plist"
            )
        }
        guard let protos = anyprotos as? [String] else {
            throw ReqError.infoParsing(error: "SupportedProtocols isn't string array")
        }
        return protos
    }}
}

struct PluginInfoProvider {
    struct Manifest: Decodable {
        let icons: [Int: String]
        
        init(bundle: Bundle) throws {
            guard let jsonUrl = bundle.url(forResource: "manifest",
                                           withExtension: "json") else
            {
                throw ReqError.infoParsing(error: "mainfest.json is not found")
            }
            let data = try Data(contentsOf: jsonUrl)
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            self = manifest
        }
        
        var bigIconPath: String? {
            let maxIcon = icons.reduce(0) { (prev, cur) in
                cur.key > prev ? cur.key : prev
            }
            return icons[maxIcon]
        }
    }
    
    let name: String
    let scheme: String
    let protocols: [String]
    let icon: String
    
    init(bundle: Bundle) throws {
        self.name = try bundle.appName
        self.scheme = try bundle.urlScheme
        self.protocols = try bundle.protocols
        
        let manifest = try Manifest(bundle: bundle)
        guard let maxIconPath = manifest.bigIconPath else {
            throw ReqError.infoParsing(error: "Icon is not found")
        }
        guard let iconUrl = bundle.url(forResource: maxIconPath,
                                       withExtension: "") else
        {
            throw ReqError.infoParsing(error: "Icon not found: " + maxIconPath)
        }
        let iconB64 = try Data(contentsOf: iconUrl).base64EncodedString()
        self.icon = "data:\(iconUrl.mimeType());base64, " + iconB64
    }
}
