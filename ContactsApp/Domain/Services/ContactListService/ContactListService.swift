//
//  ContactListService.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift

// MARK: Interface

protocol ContactListService: class {
    // Список контактов для отображения
    var contacts: Observable<[Contact]> { get }

    // true, если загрузка из инета в процессе
    var isLoading: Observable<Bool> { get }
    var error: Observable<Error> { get }

    // Устарели ли данные? Если да, то нужна принудительная загрузка с бэка
    var isOutdated: Bool { get }

    // Принудительно делает загрузку на бэк. Вызывается при pull to refresh
    func reload(force: Bool)

    // Пагинация. Вызывается, когда подходим к концу списка отображения
    func loadNext()

    // Вызывается, когда вводим текст в поле поиска
    func search(text: String)

    // Вызывается, когда завершаем поиск, нажатием на Cancel
    func endSearching()
}

// MARK: Implementation

// Сервис занимается запросом списка контактов, сохранением их локально, а также подгрузкой элементов для
// отображения с пагинацией. Для работы используется FLUX подход со стейт машиной. Это позволяет в более
// удобной форме управлять логикой работы. 
final class ContactListServiceImp {
    private let listGateway: ContactListGateway
    private let persistence: PersistenceGateway
    private let storage: StorageGateway
    private let stateScheduler: SchedulerType

    private let store: Store<ContactListState>

    private struct Constants {
        static let lastLoadTimeIntervalKey: String = "lastLoadTimeIntervalKey"
        static let outedateInterval: TimeInterval = 60
    }

    private let disposeBag: DisposeBag = .init()

    init(
        listGateway: ContactListGateway,
        persistence: PersistenceGateway,
        storage: StorageGateway,
        stateScheduler: SchedulerType
    ) {
        self.listGateway = listGateway
        self.persistence = persistence
        self.storage = storage
        self.stateScheduler = stateScheduler
        self.store = .init(scheduler: stateScheduler)
        self.store
            .feedback(feedback)
            .disposed(by: disposeBag)
    }

    private func feedback(state: Observable<ContactListState>) -> [Observable<ContactListState.Action>] {
        [
            // Наблюдаем за событием на обновление при старте.
            // Срабатывает только, когда нужно принудительно обновить список
            state
                .map { $0.initialLoad }
                .filter { $0.isForce && $0.isNeedLoad }
                .map { _ in }
                .flatMapLatest { [listGateway] in listGateway.contacts(with: .zero) }
                .do(onNext: { [storage] result in
                    // Если данные успешно загружено - сохраняем дату загрузки
                    if (try? result.get()) != nil {
                        storage.store(
                            object: Date(),
                            at: Constants.lastLoadTimeIntervalKey
                        )
                    }
                })
                .map { result in
                    switch result {
                    case let .success(contacts):
                        return ContactListState.Action.remotelyLoaded(contacts)
                    case let .failure(error):
                        return ContactListState.Action.error(error)
                    }
                },

            // Загружает список контактов из базы с пагинацией
            // Если доступен параметр фильтрации - также происходит фильтрация результатов.
            state
                .filter { $0.useCache }
                .flatMapLatest { [persistence] state in
                    persistence.getArray(range: state.cacheLoadRange) {
                        let objects = $0.sorted(byKeyPath: "name", ascending: true)
                        if let searchText = state.searchText {
                            return objects.filter(
                                NSPredicate(
                                    format: "name CONTAINS[cd] %@ OR phone CONTAINS[cd] %@", searchText, searchText
                                )
                            )
                        } else {
                            return objects
                        }
                    }
                }
                .map(ContactListState.Action.cacheLoaded),

            // Сохраняет контакты, полученные по ссылке, в базу данных
            state
                .compactMap { $0.saveContacts }
                .distinctUntilChanged()
                .flatMapLatest { [persistence] in persistence.save(objects: $0) }
                .flatMap { Observable<ContactListState.Action>.empty() }
        ]
    }
}

extension ContactListServiceImp: ContactListService {
    var contacts: Observable<[Contact]> {
        store.state.map { $0.displayContacts }
    }

    var isLoading: Observable<Bool> {
        store.state.map { $0.isLoading }
    }

    var error: Observable<Error> {
        store.state.compactMap { $0.error }
    }

    var isOutdated: Bool {
        guard let lastUpdate: Date = storage.get(for: Constants.lastLoadTimeIntervalKey) else { return true }

        return Date().timeIntervalSince(lastUpdate) > Constants.outedateInterval
    }

    func reload(force: Bool) {
        store.sink(action: .reload(forceUpdate: force))
    }

    func loadNext() {
        store.sink(action: .showNext)
    }

    func search(text: String) {
        store.sink(action: .search(text))
    }

    func endSearching() {
        store.sink(action: .disableSearch)
    }
}
