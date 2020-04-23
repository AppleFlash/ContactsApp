//
//  ContactListRouter.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

// MARK: Interface

protocol ContactListRouter: class {
    func showContactDetails(for contact: Contact)
}

// MARK: Implementation

final class ContactListRouterImp {
    private weak var controller: ContactListController?

    init(controller: ContactListController) {
        self.controller = controller
    }
}

extension ContactListRouterImp: ContactListRouter {
    func showContactDetails(for contact: Contact) {
        controller?.show(
            ContactDetailsFactory().build(with: contact),
            sender: self
        )
    }
}
