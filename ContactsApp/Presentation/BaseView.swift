//
//  BaseView.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 20.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit

class BaseView: UIView {
    init() {
        super.init(frame: .zero)

        setup()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {}

    func layout() {}
}
