//
//  NetworkingGateway.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 17.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift
import Alamofire

// MARK: Interface

protocol NetworkingGateway: class {
    func get<T: NetworkRequest>(with request: T) -> Single<T.ReturnType>
}

// MARK: Implementation

final class NetworkingGatewayImp {
    private let baseUrl: URL
    private let decoder: JSONDecoder
    private let scheduler: SchedulerType

    init(
        baseUrl: URL,
        decoder: JSONDecoder,
        scheduler: SchedulerType
    ) {
        self.baseUrl = baseUrl
        self.decoder = decoder
        self.scheduler = scheduler
    }

    private func getUrlRequest<T: NetworkRequest>(from request: T) -> URLRequest {
        var url = baseUrl
        let descriptor = request.makeRequestDescriptor()
        url.appendPathComponent(descriptor.path)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = descriptor.method.rawValue

        return urlRequest
    }
}

extension NetworkingGatewayImp: NetworkingGateway {
    func get<T: NetworkRequest>(with request: T) -> Single<T.ReturnType> {
        Single.just(getUrlRequest(from: request), scheduler: scheduler)
            .flatMap { urlRequest in
                AF
                    .request(urlRequest)
                    .validate().rx
                    .response()
            }
            .observeOn(scheduler)
            .map { [decoder] data in
                try decoder.decode(T.ReturnType.self, from: data)
            }
    }
}

extension DataRequest: ReactiveCompatible {}
extension Reactive where Base: DataRequest {
    func response() -> Single<Data> {
        Single.create { [base] single in
            base.responseData { response in
                switch response.result {
                case let .success(data):
                    single(.success(data))
                case let .failure(error):
                    single(.error(error))
                }
            }

            return Disposables.create()
        }
    }
}
