//
//  StorageGateway.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 20.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

protocol StorageGateway: class {
    func store<T>(object: T, at key: String)
    func get<T>(for key: String) -> T?
}
