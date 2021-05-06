//
//  Client.swift
//  PAYJP
//
//  Created by Li-Hsuan Chen on 2019/07/24.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

protocol ClientType {
    func request<Req: Request>(
        with request: Req,
        completion: ((Result<Req.Response, APIError>) -> Void)?
    ) -> URLSessionDataTask?
}

class Client: NSObject, ClientType {

    static let shared = Client()

    private let session: URLSession
    private let callbackQueue: CallbackQueue
    private let jsonDecoder: JSONDecoder

    private init(
        session: URLSession = URLSession(configuration: .default),
        callbackQueue: CallbackQueue = CallbackQueue.dispatch(
            DispatchQueue(label: "jp.pay.ios", attributes: .concurrent)),
        jsonDecoder: JSONDecoder = JSONDecoder.shared
    ) {
        self.session = session
        self.callbackQueue = callbackQueue
        self.jsonDecoder = jsonDecoder
    }

    @discardableResult
    func request<Req: Request>(
        with request: Req,
        completion: ((Result<Req.Response, APIError>) -> Void)?
    ) -> URLSessionDataTask? {
        do {
            let urlRequest = try request.buildUrlRequest()
            let dataTask = self.session.dataTask(with: urlRequest) { [weak self] data, response, error in
                guard let self = self else { return }

                if error != nil && data == nil && response == nil {
                    completion?(Result.failure(.systemError(error!)))
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    completion?(Result.failure(.invalidResponse(nil)))
                    return
                }

                guard let data = data else {
                    completion?(Result.failure(.invalidResponse(response)))
                    return
                }

                guard error != nil else {
                    switch response.statusCode {
                    case 200:
                        do {
                            let result = try request.response(data: data, response: response)
                            completion?(Result.success(result))
                        } catch {
                            completion?(Result.failure(.invalidJSON(data, error)))
                        }
                    case 429:
                        completion?(Result.failure(.rateLimitExceeded))
                    default:
                        do {
                            let error = try self.jsonDecoder.decode(PAYErrorResult.self, from: data).error
                            completion?(Result.failure(.serviceError(error)))
                        } catch {
                            completion?(Result.failure(.invalidJSON(data, error)))
                        }
                    }
                    return
                }
            }

            self.callbackQueue.execute { dataTask.resume() }
            return dataTask
        } catch {
            completion?(Result.failure(.systemError(error)))
            return nil
        }
    }
}
