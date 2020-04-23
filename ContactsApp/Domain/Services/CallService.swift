//
//  CallService.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 23.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit

// MARK: Interface

protocol CallService: class {
    func call(to phoneNumber: String)
}

// MARK: Implementation

final class CallServiceImp: CallService {
    func call(to phoneNumber: String) {
        guard
            let url = URL(string: "tel://\(phoneNumber)"),
            UIApplication.shared.canOpenURL(url)
        else {
            return
        }
        
        UIApplication.shared.open(url)
    }
}
