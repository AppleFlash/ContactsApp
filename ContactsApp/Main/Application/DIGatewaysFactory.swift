//
//  DIGatewaysFactory.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift

final class DIGatewaysFactory {
    private(set) lazy var contactList: ContactListGateway = ContactListGatewayImp(networking: networking)

    private lazy var networking: NetworkingGateway = NetworkingGatewayImp(
        baseUrl: URL(string: "https://raw.githubusercontent.com")!,
        decoder: decoder,
        scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: "com.scheduler.networking")
    )

    private(set) lazy var persistence: PersistenceGateway = PersistenceGatewayImp(
        configuration: .init(deleteRealmIfMigrationNeeded: true),
        scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: "com.scheduler.persistence")
    )

    private(set) lazy var userDefaultsStorage: StorageGateway = UserDefaultsStorageGateway(storage: .standard)

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return decoder
    }()

    private(set) lazy var dateFormatter: DateFormatter = {
        let dateForamtter = DateFormatter()
        dateForamtter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateForamtter
    }()

    private(set) lazy var dateDisplayFormatter: DateFormatter = {
        let dateForamtter = DateFormatter()
        dateForamtter.dateFormat = "dd.MM.yy"
        return dateForamtter
    }()
}
