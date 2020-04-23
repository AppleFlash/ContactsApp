//
//  ContactListState.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 22.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

// MARK: State

struct ContactListState {
    // Возможные экшены, которые можно передать в стейт. Только с помощью них можно изменить состояние стейта
    enum Action {
        case reload(forceUpdate: Bool)
        case showNext
        case remotelyLoaded([Contact])
        case cacheLoaded([Contact])
        case search(String)
        case disableSearch
        case error(Error)
    }

    struct InitialLoad: Equatable {
        var isNeedLoad: Bool
        var isForce: Bool
    }

    var cacheLoadRange: Range<Int>?
    var displayRange: Range<Int>?
    var isLoading: Bool = false
    var initialLoad: InitialLoad = .init(isNeedLoad: false, isForce: false)
    var displayContacts: [Contact] = []
    var saveContacts: [Contact]?
    var error: Error?
    var useCache: Bool = false
    var searchText: String?

    private let limit: Int = 50
}

extension ContactListState: StateType {
    mutating func reduce(_ action: Action) {
        error = nil
        initialLoad = .init(isNeedLoad: false, isForce: false)
        saveContacts = nil
        useCache = false

        handle(action)
    }

    // Вся логика заключена тут.
    private mutating func handle(_ action: Action) {
        switch action {
        case let .reload(force):
            guard !isLoading else { return }

            isLoading = force
            initialLoad = .init(isNeedLoad: true, isForce: force)
            if displayContacts.isEmpty {
                cacheLoadRange = 0..<limit
                useCache = true
            }

        case .showNext:
            guard
                !isLoading, let loadRange = cacheLoadRange
            else { return }

            self.cacheLoadRange = loadRange.upperBound..<loadRange.upperBound + limit
            useCache = true

        case let .remotelyLoaded(contacts):
            cacheLoadRange = 0..<limit
            isLoading = false
            saveContacts = contacts
            displayContacts = []
            useCache = true

        case let .cacheLoaded(contacts):
            displayContacts.append(contentsOf: contacts)
            displayRange = 0..<contacts.count

        case let .search(text):
            guard !isLoading else { return }

            cacheLoadRange = 0..<limit
            useCache = true
            searchText = text
            displayContacts = []

        case .disableSearch:
            guard searchText != nil else { return }

            cacheLoadRange = 0..<limit
            searchText = nil
            useCache = true
            displayContacts = []

        case let .error(error):
            self.error = error
            isLoading = false
        }
    }
}
