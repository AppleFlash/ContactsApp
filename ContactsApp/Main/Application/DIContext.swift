//
//  DIContext.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

final class DIContext {
    static let shared: DIContext = .init()

    private init() {}

    private(set) lazy var servicesFactory: DIServicesFactory = .init()
    private(set) lazy var gatewaysFactory: DIGatewaysFactory = .init()
}
