//
//  BaseViewController.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import RxSwift

class BaseViewController<View: UIView>: UIViewController {
    private let rootViewFactory: () -> View

    let disposeBag: DisposeBag = .init()

    var rootView: View {
        guard let rootView = view as? View else {
            fatalError("Unexpected type of view")
        }

        return rootView
    }

    init(rootViewFactory: @autoclosure @escaping () -> View) {
        self.rootViewFactory = rootViewFactory

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = rootViewFactory()
        view.backgroundColor = .white
    }
}
