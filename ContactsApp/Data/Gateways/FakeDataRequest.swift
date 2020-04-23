//
//  FakeDataRequest.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

struct FakeDataRequest<T: Decodable>: NetworkRequest {
    typealias ReturnType = T

    let filename: String

    func makeRequestDescriptor() -> RequestDescriptor {
        .init(
            method: .get,
            path: "SkbkonturMobile/mobile-test-ios/master/json/" + filename
        )
    }
}
