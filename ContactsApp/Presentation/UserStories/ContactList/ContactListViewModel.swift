//
//  ContactListViewModel.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 19.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift
import RxCocoa

// MARK: Interface

protocol ContactListViewModel: class {
    var items: Observable<[Contact]> { get }
    var isLoading: Driver<Bool> { get }
    var error: Driver<String> { get }

    func initialLoad()
    func reload()
    func loadNextPage()
    func search(text: String)
    func endSearch()
    func showContactInfo(for contact: Contact)
}

// MARK: Implementation

final class ContactListViewModelImp {
    private let listService: ContactListService
    private let router: ContactListRouter

    init(
        listService: ContactListService,
        router: ContactListRouter
    ) {
        self.listService = listService
        self.router = router
    }

    private func reload(force: Bool) {
        listService.reload(force: force)
    }
}

extension ContactListViewModelImp: ContactListViewModel {
    var items: Observable<[Contact]> {
        listService
            .contacts
            .distinctUntilChanged()
    }

    var isLoading: Driver<Bool> {
        listService.isLoading
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }

    var error: Driver<String> {
        listService.error
            .map { _ in
                // Как-то обрабатываем ошибку
                return "Нет подключения к сети"
            }
            .asDriver { _ in return .never() }
    }

    func initialLoad() {
        reload(force: listService.isOutdated)
    }

    func reload() {
        reload(force: true)
    }

    func loadNextPage() {
        listService.loadNext()
    }

    func search(text: String) {
        let searchText = text.trimmingCharacters(in: .whitespaces)
        guard !searchText.isEmpty else { return }

        listService.search(text: searchText)
    }

    func endSearch() {
        listService.endSearching()
    }

    func showContactInfo(for contact: Contact) {
        router.showContactDetails(for: contact)
    }
}
