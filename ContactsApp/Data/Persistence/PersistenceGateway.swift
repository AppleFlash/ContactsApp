//
//  PersistenceGateway.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RealmSwift
import RxSwift

enum PersistenceError: Error {
    case emptyArray
}

typealias ResultsBlock<T: ManagedObjectTransformable> = (Results<T.ManagedObjectType>) -> Results<T.ManagedObjectType>

protocol PersistenceGateway {
    func getArray<T: ManagedObjectTransformable>(
        range: Range<Int>?,
        block: @escaping ResultsBlock<T>
    ) -> Single<[T]>

    func save<T: ManagedObjectTransformable>(objects: [T]) -> Single<Void>
}

final class PersistenceGatewayImp {
    private let configuration: Realm.Configuration
    private let scheduler: SchedulerType

    init(
        configuration: Realm.Configuration,
        scheduler: SchedulerType
    ) {
        self.configuration = configuration
        self.scheduler = scheduler
    }

    private func realm() -> Single<Realm> {
        return Single.just(configuration, scheduler: scheduler)
            .map(Realm.init)
    }

    private func objects<T: ManagedObjectTransformable>(
        _: T.Type,
        scheduler: SchedulerType,
        block: @escaping ResultsBlock<T>
    ) -> Single<Results<T.ManagedObjectType>> {
        return realm()
            .map { $0.objects(T.ManagedObjectType.self) }
            .map(block)
    }
}

extension PersistenceGatewayImp: PersistenceGateway {
    func getArray<T: ManagedObjectTransformable>(
        range: Range<Int>?,
        block: @escaping ResultsBlock<T>
    ) -> Single<[T]> {
        return objects(T.self, scheduler: scheduler, block: block)
            .map { results in
                range.map { Array(results[$0.clamped(to: 0..<results.count)]) } ?? Array(results)
            }
            .map { $0.map { $0.plainObject } }
    }

    func save<T: ManagedObjectTransformable>(objects: [T]) -> Single<Void> {
        guard !objects.isEmpty else {
            return Single.error(PersistenceError.emptyArray)
        }

        return realm()
            .map { realm in
                try realm.write {
                    let update: Realm.UpdatePolicy = T.ManagedObjectType.primaryKey() != nil ? .modified : .all
                    let managedObjects = objects.map { $0.managedObject }
                    realm.add(managedObjects, update: update)
                }

                return ()
        }
    }
}
