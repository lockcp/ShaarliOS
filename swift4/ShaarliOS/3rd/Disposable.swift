//  https://github.com/ReactiveX/RxSwift/blob/master/RxSwift/Disposable.swift
//  Disposable.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//
/*
import Foundation

/// Represents a disposable resource.
public protocol Disposable {
    /// Dispose resource.
    func dispose()
}

// https://www.objc.io/blog/2018/04/24/bindings-with-kvo-and-keypaths/
// successor of https://github.com/objcio/issue-7-lab-color-space-explorer/blob/master/Lab%20Color%20Space%20Explorer/KeyValueObserver.m
extension NSObjectProtocol where Self: NSObject {
    func observe<Value>(_ keyPath: KeyPath<Self, Value>,
                        onChange: @escaping (Value) -> ()) -> Disposable
    {
        let observation = observe(keyPath, options: [.initial, .new]) { _, change in
            // The guard is because of https://bugs.swift.org/browse/SR-6066
            guard let newValue = change.newValue else { return }
            onChange(newValue)
        }
        return Disposable { observation.invalidate() }
    }
}

// https://www.objc.io/blog/2018/04/24/bindings-with-kvo-and-keypaths/
extension NSObjectProtocol where Self: NSObject {
    func bind<Value, Target>(_ sourceKeyPath: KeyPath<Self, Value>,
                             to target: Target,
                             at targetKeyPath: ReferenceWritableKeyPath<Target, Value>) -> Disposable
    {
        return observe(sourceKeyPath) { target[keyPath: targetKeyPath] = $0 }
    }
}
*/
