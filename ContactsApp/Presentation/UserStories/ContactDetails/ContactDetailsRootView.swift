//
//  ContactDetailsRootView.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import Stevia
import RxSwift
import RxCocoa

private final class PhoneView: BaseView {
    private let topSeparator: UIView = .init()
    private let handsetImageView: UIImageView = .init(image: #imageLiteral(resourceName: "handset"))
    private let phoneButton: UIButton = .init()
    private let phoneStack: UIStackView = .init()
    private let bottomSeparator: UIView = .init()

    var callTap: ControlEvent<Void> { phoneButton.rx.tap }

    override func setup() {
        phoneStack.alignment = .center
        let separatorColor = UIColor.lightGray.withAlphaComponent(0.3)
        topSeparator.backgroundColor = separatorColor
        handsetImageView.image = handsetImageView.image?.withTintColor(.systemBlue)
        phoneButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        phoneButton.setTitleColor(.systemBlue, for: .normal)
        bottomSeparator.backgroundColor = separatorColor
    }

    override func layout() {
        phoneStack.addArrangedSubview(handsetImageView)
        phoneStack.addArrangedSubview(phoneButton)
        phoneStack.spacing = 6

        sv(
            topSeparator,
            phoneStack,
            bottomSeparator
        )

        topSeparator.fillHorizontally().top(0).height(1)

        phoneStack.fillVertically()
        phoneStack.Left >= 16
        phoneStack.Right <= 16
        (phoneStack.CenterX == CenterX).priority = .init(749)
        phoneButton.Height == Height

        handsetImageView.size(20)

        bottomSeparator.fillHorizontally().bottom(0).height(1)
    }

    func fill(with phone: String) {
        phoneButton.setTitle(phone, for: .normal)
    }
}

final class ContactDetailsRootView: BaseView {
    private let scrollView: UIScrollView = .init()
    private let scrollContentView: UIView = .init()
    private let infoStack: UIStackView = .init()
    private let nameLabel: UILabel = .init()
    private let learnDuraitionLabel: UILabel = .init()
    private let temperamentLabel: UILabel = .init()
    private let phoneView: PhoneView = .init()
    private let bioLabel: UILabel = .init()

    var callTap: ControlEvent<Void> { phoneView.callTap }

    override func setup() {
        infoStack.axis = .vertical
        infoStack.alignment = .center

        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .black

        learnDuraitionLabel.font = .systemFont(ofSize: 16)
        learnDuraitionLabel.textColor = .lightGray

        temperamentLabel.font = .systemFont(ofSize: 14)
        temperamentLabel.textColor = .lightGray

        bioLabel.numberOfLines = 0
        bioLabel.font = .systemFont(ofSize: 14)
        bioLabel.textColor = .lightGray
        bioLabel.textAlignment = .center
        bioLabel.setContentCompressionResistancePriority(.init(752), for: .vertical)
    }

    override func layout() {
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(learnDuraitionLabel)
        infoStack.addArrangedSubview(temperamentLabel)

        sv(
            scrollView.sv(
                scrollContentView.sv(
                    infoStack, phoneView, bioLabel
                )
            )
        )

        scrollView.fillContainer()
        scrollContentView.fillContainer()
        scrollContentView.Width == scrollView.Width

        infoStack.spacing = 4
        infoStack.setCustomSpacing(6, after: nameLabel)
        infoStack
            .top(0)
            .fillHorizontally(m: 16)
        infoStack.Bottom == phoneView.Top - 16

        phoneView.fillHorizontally().height(60)
        phoneView.Bottom == bioLabel.Top - 16

        bioLabel.fillHorizontally(m: 16).bottom(16).height(40)
    }

    func fill(with info: ContactDisplayData) {
        nameLabel.text = info.name
        learnDuraitionLabel.text = info.learnDuration
        temperamentLabel.text = info.temperament
        phoneView.fill(with: info.phone)
        bioLabel.text = info.biography
    }
}
