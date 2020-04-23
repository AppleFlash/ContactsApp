//
//  Result+Utils.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

extension Result {
    var error: Error? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}

extension Array where Element: ResultConvertible {
    var firstError: Error? {
        return first { $0.result.error != nil }?.result.error
    }
}
