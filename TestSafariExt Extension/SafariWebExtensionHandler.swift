//
//  SafariWebExtensionHandler.swift
//  TestSafariExt Extension
//
//  Created by Yehor Popovych on 04/08/2023.
//

import SafariServices
import os.log

enum ReqError: Error, LocalizedError, CustomNSError {
    case badMessage(message: String)
    case fsError(error: String)
    case emptyFile(path: String)
    case badData(data: Data)
    case unknownMethod(method: String)
    case infoParsing(error: String)
    
    /// A localized message describing what error occurred.
    var errorDescription: String? {
        switch self {
        case .badMessage(message: let m): return "BadMessage: \(m)"
        case .badData(data: let data): return "BadData: \(data)"
        case .fsError(error: let error): return "FileSystemError: \(error)"
        case .emptyFile(path: let path): return "EmptyFileAt: \(path)"
        case .unknownMethod(method: let method): return "UnknownMethod: \(method)"
        case .infoParsing(error: let error): return "InfoParsing: \(error)"
        }
    }
    
    static var errorDomain: String { "SafariNativeExtension" }

    /// The error code within the given domain.
    var errorCode: Int {
        switch self {
        case .badMessage(message: _): return 1
        case .badData(data: _): return 2
        case .fsError(error: _): return 3
        case .emptyFile(path: _): return 4
        case .unknownMethod(method: _): return 5
        case .infoParsing(error: _): return 6
        }
    }
}

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private static let _initialize: Void = {
        let dir = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        let files = try! FileManager.default.contentsOfDirectory(atPath: dir.path)
        for file in files {
            if (file.hasSuffix(".request") || file.hasSuffix(".response")) {
                try! FileManager.default.removeItem(
                    at: dir.appendingPathComponent(file)
                )
            }
        }
    }()
    
    override init() {
        super.init()
        let _ = Self._initialize
    }
    
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo?[SFExtensionMessageKey]
        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", message as! CVarArg)

        guard let message = message as? [String: Any],
              let method = message["method"] as? String else
        {
            os_log(.default, "No method: %@", message as! CVarArg)
            sendErr(error: .badMessage(message: String(describing: message)),
                    context: context)
            return
        }
        switch method {
        case "info": info(context: context)
        case "send":
            guard let params = message["params"] as? Array<String>,
                  params.count == 1 else
            {
                sendErr(error: .badMessage(message: String(describing: message)),
                        context: context)
                return
            }
            write(request: params[0], context: context)
        case "receive":
            guard let params = message["params"] as? Array<String>,
                  params.count == 1 else
            {
                sendErr(error: .badMessage(message: String(describing: message)),
                        context: context)
                return
            }
            read(id: params[0], context: context)
        case "clean":
            guard let params = message["params"] as? Array<String>,
                  params.count == 1 else
            {
                sendErr(error: .badMessage(message: String(describing: message)),
                        context: context)
                return
            }
            clean(id: params[0], context: context)
        default:
            sendErr(error: .unknownMethod(method: method), context: context)
        }
    }
    
    func info(context: NSExtensionContext) {
        do {
            let info = try PluginInfoProvider(bundle: .main)
            sendOk(value: ["name": info.name,
                           "scheme": info.scheme,
                           "icon": info.icon],
                   context: context)
        } catch let error as ReqError {
            sendErr(error: error, context: context)
        } catch {
            sendErr(error: .infoParsing(error: error.localizedDescription), context: context)
        }
    }
    
    func write(request: String, context: NSExtensionContext) {
        let fm = FileManager.default
        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let dir = fm.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        let fileUrl = dir.appendingPathComponent(id + ".request")
        guard let data = request.data(using: .utf8) else {
            sendErr(error: .badMessage(message: request), context: context)
            return
        }
        do {
            try data.write(to: fileUrl)
        } catch {
            sendErr(error: .fsError(error: error.localizedDescription),
                    context: context)
            return
        }
        sendOk(value: id, context: context)
    }
    
    func read(id: String, context: NSExtensionContext) {
        let fm = FileManager.default
        let dir = fm.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        let fileUrl = dir.appendingPathComponent(id + ".response")
        if fm.fileExists(atPath: fileUrl.path) {
            guard let data = fm.contents(atPath: fileUrl.path) else {
                sendErr(error: .emptyFile(path: fileUrl.path), context: context)
                return
            }
            os_log(.default, "Contents: \(id), \(data)")
            guard let str = String(data: data, encoding: .utf8) else {
                sendErr(error: .badData(data: data), context: context)
                return
            }
            os_log(.default, "JSON: \(id), \(str)")
            do {
                try fm.removeItem(at: fileUrl)
            } catch {
                sendErr(error: .fsError(error: error.localizedDescription),
                        context: context)
                return
            }
            sendOk(value: ["finished": true, "data": str],
                   context: context)
        } else {
            sendOk(value: ["finished": false], context: context)
        }
    }
    
    func clean(id: String, context: NSExtensionContext) {
        let fm = FileManager.default
        let dir = fm.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        let reqUrl = dir.appendingPathComponent(id + ".request")
        if fm.fileExists(atPath: reqUrl.path) {
            do {
                try fm.removeItem(at: reqUrl)
            } catch {
                sendErr(error: .fsError(error: error.localizedDescription),
                        context: context)
                return
            }
        }
        let resUrl = dir.appendingPathComponent(id + ".response")
        if fm.fileExists(atPath: resUrl.path) {
            do {
                try fm.removeItem(at: resUrl)
            } catch {
                sendErr(error: .fsError(error: error.localizedDescription),
                        context: context)
                return
            }
        }
        sendOk(value: true, context: context)
    }
    
    func sendOk(value: Any, context: NSExtensionContext) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: value
        ]
        context.completeRequest(returningItems: [response])
    }
    
    func sendErr(error: ReqError, context: NSExtensionContext) {
        context.cancelRequest(withError: error)
    }
}
