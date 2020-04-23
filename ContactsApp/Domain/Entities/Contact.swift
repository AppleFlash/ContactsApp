//
//  Contact.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import Foundation

struct Contact: Codable, Equatable {
    enum Temperament: String, Codable {
        case melancholic, phlegmatic, sanguine, choleric
    }

    struct EducationPeriod: Codable, Equatable {
        let start: Date
        let end: Date
    }

    let id: String
    let name: String
    let phone: String
    let height: Float
    let biography: String
    let temperament: Temperament
    let educationPeriod: EducationPeriod
}
