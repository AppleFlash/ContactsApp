//
//  ManagedContact.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RealmSwift

// MARK: Managed object

final class ManagedContact: Object, PlainObjectTransformable {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var phone: String = ""
    @objc dynamic var height: Float = 0
    @objc dynamic var biography: String = ""
    @objc dynamic var temperament: String = ""
    @objc dynamic var educationStart: Date = .distantPast
    @objc dynamic var educationEnd: Date = .distantPast

    override static func primaryKey() -> String { return "id" }

    override class func indexedProperties() -> [String] { ["name", "phone"] }

    // MARK: PlainObjectTransformable

    typealias PlainObjectType = Contact

    var plainObject: PlainObjectType { .init(managed: self) }

    required convenience init(plain object: PlainObjectType) {
        self.init()

        self.id = object.id
        self.name = object.name
        self.phone = object.phone
        self.height = object.height
        self.biography = object.biography
        self.temperament = object.temperament.rawValue
        self.educationStart = object.educationPeriod.start
        self.educationEnd = object.educationPeriod.end
    }
}

// MARK: Plain object

extension Contact: ManagedObjectTransformable {
    typealias ManagedObjectType = ManagedContact

    var managedObject: ManagedObjectType { .init(plain: self) }

    init(managed object: ManagedObjectType) {
        self.id = object.id
        self.name = object.name
        self.phone = object.phone
        self.height = object.height
        self.biography = object.biography
        let temperament = Contact.Temperament(rawValue: object.temperament)
        assert(temperament != nil)
        self.temperament = temperament ?? .melancholic
        self.educationPeriod = .init(
            start: object.educationStart,
            end: object.educationEnd
        )
    }
}
