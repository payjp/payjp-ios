//
//  ThreeDSecureProcessHandlerExampleView.swift
//  example-swift
//

import SwiftUI
import PAYJP

class ThreeDSecureViewModel: ObservableObject, ThreeDSecureProcessHandlerDelegate {
    @Published var pendingResourceId: String = ""
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var isError: Bool = false
    
    func startThreeDSecureProcess() {
        guard !pendingResourceId.isEmpty,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            showResult = false
            return
        }
        ThreeDSecureProcessHandler.shared.startThreeDSecureProcess(
            viewController: rootViewController,
            delegate: self,
            resourceId: pendingResourceId
        )
    }
    
    // MARK: - ThreeDSecureProcessHandlerDelegate
    func threeDSecureProcessHandlerDidFinish(_ handler: ThreeDSecureProcessHandler, status: ThreeDSecureProcessStatus) {
        switch status {
        case .completed:
            DispatchQueue.main.async {
                self.resultMessage = """
                    3Dセキュア認証が終了しました。
                    この結果をサーバーサイドに伝え、完了処理や結果のハンドリングを行なってください。
                    後続処理の実装方法に関してはドキュメントをご参照ください。
                    """
                self.showResult = true
                self.isError = false
            }
        case .canceled:
            DispatchQueue.main.async {
                self.resultMessage = "3Dセキュア認証がキャンセルされました。"
                self.showResult = true
                self.isError = true
            }
        }
    }
}

struct ThreeDSecureProcessHandlerExampleView: View {
    @ObservedObject private var viewModel = ThreeDSecureViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("リソースIDを入力してください（ch_xxxx または tdsr_xx など）。",
                          text: $viewModel.pendingResourceId
                )
                .padding()
                .border(Color.gray, width: 1)
                .padding(.horizontal)
                
                if viewModel.showResult {
                    Text(viewModel.resultMessage)
                        .foregroundColor(viewModel.isError ? .red : .black)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    // 3) Call the view model's start function
                    viewModel.startThreeDSecureProcess()
                }) {
                    Text("3Dセキュア開始")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1.下記を参考に、先にサーバーサイドで支払い、または3Dセキュアリクエストを作成してください。")
                    
                    Text("支払い作成時の3Dセキュア：")
                    if let url = URL(string: "https://pay.jp/docs/charge-tds") {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text("https://pay.jp/docs/charge-tds")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("顧客カードに対する3Dセキュア：")
                    if let url = URL(string: "https://pay.jp/docs/customer-card-tds") {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text("https://pay.jp/docs/customer-card-tds")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. 作成したリソースのIDを上記に入力して3Dセキュアを開始してください。")
                    
                    Text("3.立ち上がった画面が閉じ、認証が終了したら、ドキュメントを参考にサーバーサイドにて結果を確認してください。")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitle("3Dセキュア")
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ThreeDSecureProcessHandlerExampleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThreeDSecureProcessHandlerExampleView()
        }
    }
}
