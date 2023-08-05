//
//  WalletModel.swift
//  TestSafariExt
//
//  Created by Yehor Popovych on 04/08/2023.
//

import Foundation

class WalletModel: ObservableObject {
    private var defaults: UserDefaults
    
    private struct Response: Encodable {
        let response: String?
        let error: String?
    }
    
    @Published var signature: String {
        didSet {
            defaults.set(signature, forKey: "signature")
        }
    }
    
    @Published var requestId: String?
    @Published var error: String?
    
    var request: String?
    
    convenience init() {
        self.init(requestId: nil, request: nil, error: nil, signature: nil)
    }
    
    init(requestId: String?, request: String?, error: String?, signature: String?) {
        self.defaults = UserDefaults(suiteName: "group.tesseract.shared")!
        self.request = request
        self.signature = signature ?? defaults.string(forKey: "signature") ?? "_signed"
        self.error = error
        self.requestId = requestId
    }
    
    func openUrl(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else {
            error = "Bad url: \(url)"
            return
        }
        guard let req = items.first(where: { $0.name == "req" }) else {
            error = "Request ID not found: \(items)"
            return
        }
        guard let id = req.value else {
            error = "Request value is empty"
            return
        }
        let fm = FileManager.default
        let dirUrl = fm.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        let fileUrl = dirUrl.appendingPathComponent(id + ".request")
        guard fm.fileExists(atPath: fileUrl.path) else {
            error = "Request file doesn't exist: \(id)"
            sendError(error: error!)
            return
        }
        guard let data = fm.contents(atPath: fileUrl.path) else {
            error = "Can't read file: \(id)"
            sendError(error: error!)
            return
        }
        guard let string = String(data: data, encoding: .utf8) else {
            error = "Bad request data: \(data)"
            sendError(error: error!)
            return
        }
        request = string
        requestId = id
    }
    
    func sendResponse(message: String) {
        guard let id = requestId else {
            error = "Request ID is nil"
            return
        }
        sendResponse(id: id, res: Response(response: message, error: nil))
    }
    
    func sendError(error: String) {
        guard let id = requestId else {
            self.error = "Request ID is nil"
            return
        }
        sendResponse(id: id, res: Response(response: nil, error: error))
    }
    
    private func sendResponse(id: String, res: Response) {
        let data = try! JSONEncoder().encode(res)
        let tempId = UUID().uuidString.replacingOccurrences(of: "-", with: "_")
        let tempUrl = responseURL(id: tempId)
        let finishedUrl = responseURL(id: id)
        try! data.write(to: tempUrl)
        try! FileManager.default.moveItem(at: tempUrl, to: finishedUrl)
        let _ = OS_GO_BACK(application: .shared)
        self.requestId = nil
        self.request = nil
    }
    
    private func responseURL(id: String) -> URL {
        let fm = FileManager.default
        let dirUrl = fm.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tesseract.shared"
        )!
        return dirUrl.appendingPathComponent(id + ".response")
    }
}
