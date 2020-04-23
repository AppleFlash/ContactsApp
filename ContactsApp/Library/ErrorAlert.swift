//
//  ErrorAlert.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 23.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import Stevia

private final class ErrorWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

class ErrorAlert {
    static let shared: ErrorAlert = .init()

    private var message: String?
    private var window: ErrorWindow?
    private var messageLabel: UILabel?
    private var messageContainer: UIView?

    private init() {}

    func show(with message: String) {
        if let currentWindow = window, !currentWindow.isHidden {
            if self.message == message {
                return
            } else {
                messageLabel?.text = message
                self.message = message
            }
        }

        self.message = message
        window = .init(frame: UIScreen.main.bounds)
        window?.rootViewController = makeController(for: message)
        window?.isHidden = false

        messageContainer.map(show)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }

            if let view = self.messageContainer {
                self.hide(view: view) {
                    self.window?.isHidden = true
                    self.window = nil
                    self.message = nil
                    self.messageLabel = nil
                    self.messageContainer = nil
                }
            } else {
                self.window?.isHidden = true
                self.window = nil
            }
        }
    }

    private func makeController(for message: String) -> UIViewController {
        let containerController = UIViewController()
        containerController.view.backgroundColor = .clear

        let view = UIView()
        view.alpha = 0
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 5

        containerController.view.sv(view)
        view.height(44).fillHorizontally(m: 24)
        view.Bottom == containerController.view.safeAreaLayoutGuide.Bottom - 16

        let messageLabel: UILabel = .init()
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.text = message

        view.sv(messageLabel)
        messageLabel.fillContainer(8)

        self.messageLabel = messageLabel
        self.messageContainer = view

        return containerController
    }

    private func show(view: UIView) {
        UIView.animate(withDuration: 0.25) {
            view.alpha = 1
        }
    }

    private func hide(view: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            view.alpha = 0
        }, completion: { _ in
            completion()
        })
    }
}
