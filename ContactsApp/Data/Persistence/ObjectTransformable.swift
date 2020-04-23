//
//  ObjectTransformable.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RealmSwift

protocol ManagedObjectTransformable {
    associatedtype ManagedObjectType: Object, PlainObjectTransformable where ManagedObjectType.PlainObjectType == Self

    var managedObject: ManagedObjectType { get }

    init(managed object: ManagedObjectType)
}

protocol PlainObjectTransformable {
    associatedtype PlainObjectType: ManagedObjectTransformable where PlainObjectType.ManagedObjectType == Self

    var plainObject: PlainObjectType { get }

    init(plain object: PlainObjectType)
}
