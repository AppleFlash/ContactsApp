//
//  ContactDetailsController.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import RxSwift

final class ContactDetailsController: BaseViewController<ContactDetailsRootView> {
    var viewModel: ContactDetailsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        rootView.fill(with: viewModel.contactDisplayData)

        rootView.callTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [viewModel] in
                viewModel?.call()
            })
            .disposed(by: disposeBag)
    }
}
