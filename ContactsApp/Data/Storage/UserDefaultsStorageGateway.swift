//
//  UserDefaultsStorageGateway.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 20.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import Foundation

final class UserDefaultsStorageGateway {
    let storage: UserDefaults

    init(storage: UserDefaults) {
        self.storage = storage
    }
}

extension UserDefaultsStorageGateway: StorageGateway {
    func store<T>(object: T, at key: String) {
        storage.set(object, forKey: key)
    }

    func get<T>(for key: String) -> T? {
        return storage.object(forKey: key) as? T
    }
}
