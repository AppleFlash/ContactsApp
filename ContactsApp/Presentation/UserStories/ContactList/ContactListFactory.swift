//
//  ContactListFactory.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift

final class ContactListFactory: SceneFactory {
    func build(with context: ()) -> ContactListController {
        let rootView = ContactListRootView()
        let controller = ContactListController(rootViewFactory: rootView)
        let router = ContactListRouterImp(controller: controller)
        let listService = ContactListServiceImp(
            listGateway: DIContext.shared.gatewaysFactory.contactList,
            persistence: DIContext.shared.gatewaysFactory.persistence,
            storage: DIContext.shared.gatewaysFactory.userDefaultsStorage,
            stateScheduler: MainScheduler.asyncInstance
        )
        let viewModel = ContactListViewModelImp(
            listService: listService,
            router: router
        )
        controller.viewModel = viewModel

        return controller
    }
}
