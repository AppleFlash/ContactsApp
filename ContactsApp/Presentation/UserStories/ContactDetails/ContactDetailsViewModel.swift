//
//  ContactDetailsViewModel.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit

protocol ContactDetailsViewModel: class {
    var contactDisplayData: ContactDisplayData { get }

    func call()
}

final class ContactDetailsViewModelImp: NSObject {
    private let contact: Contact
    private let callService: CallService
    let contactDisplayData: ContactDisplayData

    init(
        contact: Contact,
        dateFormatter: DateFormatter,
        callService: CallService
    ) {
        self.contact = contact
        self.callService = callService

        let startStringDate = dateFormatter.string(from: contact.educationPeriod.start)
        let endStringDate = dateFormatter.string(from: contact.educationPeriod.end)
        self.contactDisplayData = ContactDisplayData(
            name: contact.name,
            learnDuration: "\(startStringDate) - \(endStringDate)",
            temperament: contact.temperament.rawValue.capitalized,
            phone: contact.phone,
            biography: contact.biography
        )
    }
}

extension ContactDetailsViewModelImp: ContactDetailsViewModel {
    func call() {
        callService.call(
            to: contact.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        )
    }
}
