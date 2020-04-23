//
//  ResultConvertible.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

protocol ResultConvertible {
    associatedtype Success
    associatedtype Failure: Swift.Error

    var result: Swift.Result<Success, Failure> { get }
}

extension Result: ResultConvertible {
    var result: Result<Success, Failure> { self }
}
