//
//  SignView.swift
//  TestSafariExt
//
//  Created by Yehor Popovych on 05/08/2023.
//

import SwiftUI

struct SignView: View {
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
                    Text("Sign Message")
                        .font(.system(size: 48))
                    Spacer()
                }
                .padding()
                HStack {
                    Text("Message:")
                    Spacer()
                }
                .padding()
                HStack {
                    Text(model.request ?? "")
                    Spacer()
                }
                .padding()
                HStack {
                    Button("Sign") {
                        model.sendResponse(message: model.request! + model.signature)
                    }.padding()
                    Spacer()
                    Button("Cancel") {
                        model.sendError(error: "cancelled")
                    }.padding()
                }
                HStack {
                    Text(model.error ?? "")
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView(model: WalletModel(requestId: "1234", request: "Some request", error: nil, signature: "_signed"))
    }
}
