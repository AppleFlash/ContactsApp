//
//  ContactListController.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

// Обычно для работы с таблицами в связке с rx использую другую либу. Но тут, для разнообразия используется
// более нативный подход для rx. К сожалению, приходится городить такое, когда используешь данные для отображения
// в одной секции
private struct SectionData: AnimatableSectionModelType {
    typealias Item = Contact
    
    var identity: Int { 0 }
    var items: [SectionData.Item]

    init(original: Self, items: [Self.Item]) {
        self = original
        self.items = items
    }

    init(items: [Self.Item]) {
        self.items = items
    }
}

extension Contact: IdentifiableType {
    typealias Identity = String
    var identity: Contact.Identity { id }
}

// MARK: Controller

class ContactListController: BaseViewController<ContactListRootView> {
    typealias KeyboardAnimationInfo = (position: CGFloat, duration: TimeInterval)

    private let preloadItemsCount: Int = 3

    // Вынесено в переменную, чтобы немного улучшить производительность, т.к. count нужно вызывать при
    // каждом отображении ячейки для проверки нужно ли подгружать следующую страницу
    private var itemsCount: Int = 0
    private let searchController: UISearchController = .init(searchResultsController: nil)

    var viewModel: ContactListViewModel!
    private lazy var dataSource: RxTableViewSectionedAnimatedDataSource<SectionData> = .init(
        animationConfiguration: .init(insertAnimation: .none, reloadAnimation: .none, deleteAnimation: .fade),
        configureCell: { [unowned self] _, tableView, indexPath, contact in
            self.loadNextPageIfNeeded(indexPath: indexPath)
            return self.rootView.tableCell(for: tableView, at: indexPath, with: contact)
        }
    )

    private lazy var keyboardObserver: Observable<KeyboardAnimationInfo> = {
        let notificationCenter = NotificationCenter.default
        return Observable
            .merge([
                notificationCenter.rx.notification(UIWindow.keyboardWillShowNotification),
                notificationCenter.rx.notification(UIWindow.keyboardWillChangeFrameNotification),
                notificationCenter.rx.notification(UIWindow.keyboardWillHideNotification),
            ])
            .map { [unowned self] notification in
                self.keyboardAnimationInfo(from: notification)
            }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureBindings()
        viewModel.initialLoad()
    }

    private func configureAppearance() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesSearchBarWhenScrolling = false

        title = "Contacts"

        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
    }

    private func configureBindings() {
        viewModel.items
            .do(onNext: { [unowned self] in
                self.itemsCount = $0.count
            })
            .map { [SectionData(items: $0)] }
            .bind(to: rootView.tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        viewModel.isLoading
            .drive(rootView.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewModel.error
            .drive(onNext: {
                ErrorAlert.shared.show(with: $0)
            })
            .disposed(by: disposeBag)

        rootView.refreshControl.rx
            .controlEvent(.valueChanged)
            .withLatestFrom(viewModel.isLoading)
            .subscribe(onNext: { [rootView, viewModel] isLoading in
                if isLoading {
                    rootView.refreshControl.endRefreshing()
                } else {
                    viewModel?.reload()
                }
            })
            .disposed(by: disposeBag)

        searchController.searchBar.rx
            .text
            .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .compactMap { $0 }
            .subscribe(onNext: { [viewModel] in
                viewModel?.search(text: $0)
            })
            .disposed(by: disposeBag)

        searchController.searchBar.rx
            .cancelButtonClicked
            .subscribe(onNext: { [viewModel] in
                viewModel?.endSearch()
            })
            .disposed(by: disposeBag)

        keyboardObserver
            .subscribe(onNext: { [rootView] info in
                rootView.tableView.contentInset.bottom = info.position
                rootView.tableView.verticalScrollIndicatorInsets.bottom = info.position
            })
            .disposed(by: disposeBag)

        rootView.tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        rootView.tableView.rx
            .modelSelected(Contact.self)
            .subscribe(onNext: { [viewModel] in
                viewModel?.showContactInfo(for: $0)
            })
            .disposed(by: disposeBag)
    }

    private func loadNextPageIfNeeded(indexPath: IndexPath) {
        guard indexPath.row >= itemsCount - preloadItemsCount - 1 else { return }

        viewModel.loadNextPage()
    }

    private func keyboardAnimationInfo(from notification: Notification) -> KeyboardAnimationInfo {
        let keyboardFrameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardAnimationDurationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[keyboardFrameKey] as? CGRect,
            let duration = userInfo[keyboardAnimationDurationKey] as? TimeInterval
        else {
            return KeyboardAnimationInfo(position: 0, duration: 0)
        }

        var yPosition: CGFloat
        if notification.name == UIWindow.keyboardWillHideNotification {
            yPosition = 0
        } else {
            yPosition = abs(keyboardFrame.height)
            yPosition -= max(0, view.safeAreaInsets.bottom)
        }

        return KeyboardAnimationInfo(position: yPosition, duration: duration)
    }
}

extension ContactListController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
