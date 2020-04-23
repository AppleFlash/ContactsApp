//
//  DIServicesFactory.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift

final class DIServicesFactory {
    private(set) lazy var callService: CallService = CallServiceImp()
}
