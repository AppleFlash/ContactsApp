//
//  ContactsGateway.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift

struct Pagination {
    let offset: Int
    let limit: Int

    static let zero: Pagination = .init(offset: 0, limit: 0)
}

// MARK: Interface

protocol ContactListGateway: class {
    func contacts(with pagination: Pagination) -> Single<Result<[Contact], Error>>
}

// MARK: Implementation

// Получаем данные из гитхаба. Гейтвей содержит буфер данных, чтобы имитировать ответ сервера с пагинацией
final class ContactListGatewayImp {
    private let networking: NetworkingGateway

    // Список возможных файлов для запроса данных
    private let filenames: [String] = ["generated-01.json", "generated-02.json", "generated-03.json"]

    init(networking: NetworkingGateway) {
        self.networking = networking
    }

    private func makeRequest(for filename: String) -> Single<Result<[Contact], Error>> {
        return networking.get(with: FakeDataRequest(filename: filename))
            .map(Result.success)
            .catchError { .just(.failure($0)) }
    }
}

extension ContactListGatewayImp: ContactListGateway {
    // Пагинация фактически не исопльзуется, т.к. это повлечет большие неудобства при поиска в данном случае.
    // Т.к. используются тестовые данные, то проще делать запрос на все файлы сразу
    func contacts(with pagination: Pagination) -> Single<Result<[Contact], Error>> {
        Single
            .zip(filenames.map(makeRequest))
            .map { results -> Result<[Contact], Error> in
                if let error = results.firstError {
                    return .failure(error)
                } else {
                    let objects = results
                        .lazy
                        .compactMap { try? $0.get() }
                        .reduce([], +)
                    return .success(objects)
                }
            }
    }
}
