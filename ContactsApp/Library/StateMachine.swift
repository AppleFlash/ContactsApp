//
//  StateMachine.swift
//  ContactsApp
//
//  Created by Vladislav Sedinkin on 18.04.2020.
//  Copyright © 2020 Vladislav Sedinkin. All rights reserved.
//

import RxSwift
import RxCocoa

protocol EmptyInitializable {
    init()
}

protocol StateType: EmptyInitializable {
    associatedtype Action

    mutating func reduce(_ action: Action)
}

typealias Feedback<T: StateType> = (Observable<T>) -> Observable<T.Action>

final class Store<T: StateType> {
    private let stateObservable: Observable<T>
    private let actionSubject: PublishSubject<T.Action> = .init()
    private let disposeBag: DisposeBag = .init()

    init(initialState: T = T(), scheduler: SchedulerType) {
        self.stateObservable = actionSubject
            .observeOn(scheduler)
            .scan(initialState) { state, action in
                var state = state
                state.reduce(action)
                return state
            }
            .startWith(initialState)
            .share(replay: 1)

        stateObservable.subscribe().disposed(by: disposeBag)
    }

    var state: Observable<T> { stateObservable }

    func sink(action: T.Action) {
        actionSubject.onNext(action)
    }

    func sink() -> (T.Action) -> Void {
        return { [actionSubject] action in
            actionSubject.onNext(action)
        }
    }
}

extension Store {
    func feedback(_ block: (Observable<T>) -> [Observable<T.Action>]) -> Disposable {
        return Observable.from(block(stateObservable))
            .flatMap { $0 }
            .concat(Observable.never())
            .bind(to: actionSubject)
    }
}
