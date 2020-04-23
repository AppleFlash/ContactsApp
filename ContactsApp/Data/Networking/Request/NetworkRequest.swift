//
//  NetworkRequest.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 17.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

protocol NetworkRequest {
    associatedtype ReturnType: Decodable

    func makeRequestDescriptor() -> RequestDescriptor
}
