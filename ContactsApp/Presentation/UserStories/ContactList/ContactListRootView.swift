//
//  ContactListRootView.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import Stevia
import RxSwift
import RxCocoa

class ContactListRootView: BaseView {
    let tableView: UITableView = .init()
    let refreshControl: UIRefreshControl = .init()

    private let cellIdentifier: String = "cell"

    override func setup() {
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = 60
        tableView.addSubview(refreshControl)
    }

    override func layout() {
        sv(tableView)
        tableView.fillContainer()
    }

    func tableCell(
        for tableView: UITableView,
        at indexPath: IndexPath,
        with item: Contact
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ContactTableViewCell
        else {
            fatalError("Wrong cell type")
        }
        cell.fill(with: item)

        return cell
    }
}

extension Reactive where Base: UIRefreshControl {
    public var isRefreshing: Binder<Bool> {
        return Binder(base) { target, refresh in
            if refresh {
                target.beginRefreshing()
            } else {
                target.endRefreshing()
            }
        }
    }
}
