//
//  ContentView.swift
//  PayJPCheckoutExample
//
//  2026/01/19.
//

import SwiftUI
import SafariServices
import Combine

// MARK: - Models

struct CheckoutSessionResponse: Decodable {
    let id: String
    let url: String
    let status: String
}

struct SampleProduct: Identifiable, Decodable {
    let id: String
    let name: String
    let amount: Int
}

struct ProductsResponse: Decodable {
    let products: [SampleProduct]
}

// MARK: - ViewModel

class CheckoutViewModel: ObservableObject {
    @Published var backendURL: String = "http://localhost:3000"
    @Published var selectedProduct: SampleProduct?
    @Published var isLoading: Bool = false
    @Published var checkoutURL: URL?
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var isError: Bool = false
    @Published var products: [SampleProduct] = []
    @Published var isLoadingProducts: Bool = false
    @Published var productsErrorMessage: String = ""

    private var notificationObserver: Any?

    init() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .checkoutRedirect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let url = notification.userInfo?["url"] as? URL {
                self?.handleRedirectURL(url)
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func fetchProductsIfNeeded() {
        if products.isEmpty && !isLoadingProducts {
            fetchProducts()
        }
    }

    func fetchProducts() {
        guard !backendURL.isEmpty else {
            productsErrorMessage = "サーバーURLを入力してください"
            return
        }

        guard let serverURL = URL(string: backendURL) else {
            productsErrorMessage = "無効なURLです"
            return
        }

        isLoadingProducts = true
        productsErrorMessage = ""
        selectedProduct = nil

        let endpoint = serverURL.appendingPathComponent("products")
        URLSession.shared.dataTask(with: endpoint) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoadingProducts = false

                if let error = error {
                    self?.productsErrorMessage = "商品一覧の取得に失敗しました: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self?.productsErrorMessage = "商品一覧の取得に失敗しました"
                    return
                }

                do {
                    let payload = try JSONDecoder().decode(ProductsResponse.self, from: data)
                    self?.products = payload.products
                    if payload.products.isEmpty {
                        self?.productsErrorMessage = "商品が登録されていません"
                    }
                } catch {
                    if let errorResponse = String(data: data, encoding: .utf8) {
                        self?.productsErrorMessage = "商品一覧の解析に失敗しました: \(errorResponse)"
                    } else {
                        self?.productsErrorMessage = "商品一覧の解析に失敗しました"
                    }
                }
            }
        }.resume()
    }

    func createCheckoutSession() {
        guard let product = selectedProduct else {
            showError("商品を選択してください")
            return
        }

        guard !backendURL.isEmpty else {
            showError("サーバーURLを入力してください")
            return
        }

        guard let serverURL = URL(string: backendURL) else {
            showError("無効なURLです")
            return
        }

        isLoading = true
        showResult = false

        let endpoint = serverURL.appendingPathComponent("create-checkout-session")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "price_id": product.id,
            "quantity": 1,
            "success_url": "payjpcheckoutexample://checkout/success",
            "cancel_url": "payjpcheckoutexample://checkout/cancel"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.handleCheckoutResponse(data: data, error: error)
            }
        }.resume()
    }

    private func handleCheckoutResponse(data: Data?, error: Error?) {
        isLoading = false

        if let error = error {
            showError("通信エラー: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            showError("データが取得できませんでした")
            return
        }

        do {
            let session = try JSONDecoder().decode(CheckoutSessionResponse.self, from: data)
            if let url = URL(string: session.url) {
                checkoutURL = url
            } else {
                showError("無効なチェックアウトURLです")
            }
        } catch {
            if let errorResponse = String(data: data, encoding: .utf8) {
                showError("エラー: \(errorResponse)")
            } else {
                showError("レスポンスの解析に失敗しました")
            }
        }
    }

    func handleRedirectURL(_ url: URL) {
        checkoutURL = nil

        if url.absoluteString.contains("success") {
            resultMessage = "決済が完了しました！"
            isError = false
        } else if url.absoluteString.contains("cancel") {
            resultMessage = "決済がキャンセルされました"
            isError = true
        } else {
            resultMessage = "不明なリダイレクト: \(url.absoluteString)"
            isError = true
        }
        showResult = true
    }

    private func showError(_ message: String) {
        resultMessage = message
        isError = true
        showResult = true
    }
}

// MARK: - View

struct ContentView: View {
    @StateObject var viewModel = CheckoutViewModel()
    @State var showSafari = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("1. サンプルサーバーURL")) {
                    TextField("https://your-server.com", text: $viewModel.backendURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        viewModel.fetchProducts()
                    }) {
                        HStack {
                            if viewModel.isLoadingProducts {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("商品一覧を取得")
                        }
                    }
                    .disabled(viewModel.isLoadingProducts || viewModel.backendURL.isEmpty)
                }

                Section(header: Text("2. 商品を選択")) {
                    if !viewModel.productsErrorMessage.isEmpty {
                        Text(viewModel.productsErrorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    } else if viewModel.products.isEmpty {
                        Text("商品一覧が空です。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.products) { product in
                            HStack {
                                Image(systemName: viewModel.selectedProduct?.id == product.id
                                        ? "largecircle.fill.circle"
                                        : "circle")
                                    .foregroundColor(.blue)

                                Text(product.name)
                                Spacer()
                                Text("¥\(product.amount)")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedProduct = product
                            }
                        }
                    }
                }

                Section(header: Text("3. 決済を開始")) {
                    Button(action: {
                        viewModel.createCheckoutSession()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Checkout V2 で支払う")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.selectedProduct == nil || viewModel.backendURL.isEmpty)
                }

                if viewModel.showResult {
                    Section(header: Text("結果")) {
                        HStack {
                            Image(systemName: viewModel.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(viewModel.isError ? .red : .green)
                            Text(viewModel.resultMessage)
                                .font(.subheadline)
                        }
                    }
                }

            }
            .navigationTitle("Checkout V2 サンプル")
            .onChange(of: viewModel.checkoutURL) { _, newURL in
                showSafari = (newURL != nil)
            }
            .sheet(isPresented: $showSafari) {
                if let url = viewModel.checkoutURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                viewModel.fetchProductsIfNeeded()
            }
        }
    }
}

// MARK: - SFSafariViewController Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safariVC = SFSafariViewController(url: url, configuration: config)
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    ContentView()
}
