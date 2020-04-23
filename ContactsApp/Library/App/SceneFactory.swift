//
//  SceneFactory.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit

protocol FactoryType {
    associatedtype Context
    associatedtype Product

    func build(with context: Context) -> Product
}

protocol SceneFactory: FactoryType where Product: UIViewController {
    func build(with context: Context) -> Product
}
