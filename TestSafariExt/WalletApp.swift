//
//  WalletApp.swift
//  TestSafariExt
//
//  Created by Yehor Popovych on 04/08/2023.
//

import SwiftUI

@main
struct WalletApp: App {
    @StateObject var model = WalletModel()
    
    var body: some Scene {
        WindowGroup {
            if model.requestId != nil {
                SignView(model: model)
            } else {
                MainView(model: model)
                    .onOpenURL { model.openUrl(url: $0) }
            }
            
        }
    }
}
