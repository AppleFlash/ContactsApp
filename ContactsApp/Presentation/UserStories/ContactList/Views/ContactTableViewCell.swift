//
//  ContactTableViewCell.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import Stevia

class ContactTableViewCell: UITableViewCell {
    private let nameLabel: UILabel = .init()
    private let phoneLabel: UILabel = .init()
    private let infoStack: UIStackView = .init()
    private let temperamentLabel: UILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        nameLabel.font = .boldSystemFont(ofSize: 14)
        nameLabel.textColor = .black
        nameLabel.setContentHuggingPriority(
            nameLabel.contentHuggingPriority(for: .vertical) + 1,
            for: .vertical
        )

        phoneLabel.font = .systemFont(ofSize: 12)
        phoneLabel.textColor = .lightGray

        infoStack.axis = .vertical
        infoStack.spacing = 4

        temperamentLabel.font = .systemFont(ofSize: 12)
        temperamentLabel.textColor = .lightGray
        temperamentLabel.setContentHuggingPriority(
            temperamentLabel.contentHuggingPriority(for: .horizontal) + 1,
            for: .horizontal
        )
        temperamentLabel.setContentCompressionResistancePriority(.init(753), for: .horizontal)

        accessoryType = .disclosureIndicator
    }

    private func layout() {
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(phoneLabel)

        sv(infoStack, temperamentLabel)

        infoStack.left(24)
        infoStack.Right == temperamentLabel.Left - 8
        infoStack.Top >= 4
        infoStack.Bottom <= 4
        (infoStack.CenterY == CenterY).priority = .init(749)

        temperamentLabel
            .fillVertically()
            .right(16)
    }

    func fill(with contact: Contact) {
        nameLabel.text = contact.name
        phoneLabel.text = contact.phone
        temperamentLabel.text = contact.temperament.rawValue
    }
}
