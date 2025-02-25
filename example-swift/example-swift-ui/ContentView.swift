//
//  ContentView.swift
//  example-swift-ui
//
//  Created by Tatsuya Kitagawa on 2020/07/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("カードフォーム")) {
                    NavigationLink(destination: CardFormViewControllerExampleView()) {
                        Text("Card Form ViewController")
                    }
                }
                Section(header: Text("支払い時の3Dセキュア、または顧客カードの3Dセキュア")) {
                    NavigationLink(destination: ThreeDSecureProcessHandlerExampleView()) {
                        Text("ThreeD Secure Process Handler")
                    }
                }
            }
            .navigationBarTitle("Example")
        }
    }
}


// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
