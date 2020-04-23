//
//  ContactDetailsFactory.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit

final class ContactDetailsFactory: SceneFactory {
    func build(with contact: Contact) -> ContactDetailsController {
        let rootView = ContactDetailsRootView()
        let controller = ContactDetailsController(rootViewFactory: rootView)
        let viewModel = ContactDetailsViewModelImp(
            contact: contact,
            dateFormatter: DIContext.shared.gatewaysFactory.dateDisplayFormatter,
            callService: DIContext.shared.servicesFactory.callService
        )
        controller.viewModel = viewModel

        return controller
    }
}
