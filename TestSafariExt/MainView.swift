//
//  MainView.swift
//  TestSafariExt
//
//  Created by Yehor Popovych on 05/08/2023.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var model: WalletModel
    
    var body: some View {
        ZStack {
            Color(red: 0xFF/0xFF,
                  green: 0x7D/0xFF,
                  blue: 0x00/0xFF)
                .edgesIgnoringSafeArea(.top)
            Color.white
            VStack {
                HStack {
                    Text("Tesseract\nDemo Wallet")
                        .font(.system(size: 48))
                    Spacer()
                }
                .padding()
                HStack {
                    Text("Choose your signature:")
                    Spacer()
                }
                .padding()
                TextField("Signature", text: $model.signature)
                    .padding()
                Spacer()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(model:
                    WalletModel(requestId: nil, request: nil, error: nil, signature: "_signed")
        )
    }
}
