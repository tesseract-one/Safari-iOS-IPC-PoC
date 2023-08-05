//
//  GoBack.swift
//  TestSafariExt
//
//  Created by Yehor Popovych on 04/08/2023.
//

import UIKit
import ObjectiveC

private typealias SendResponseForDestination = @convention(c) (Any, Selector, UInt) -> Bool

func OS_GO_BACK(application: UIApplication) -> Bool {
    let propName = "_systemNavigationAction"
    let destSelector = Selector(("destinations"))
    let sendSelector = Selector(("sendResponseForDestination:"))
    guard let sysNavIvar = class_getInstanceVariable(UIApplication.self, propName) else {
        return false
    }
    guard let action = object_getIvar(application, sysNavIvar) as? NSObject else {
        return false
    }
    guard let destinations = action.perform(destSelector).takeUnretainedValue() as? NSArray else {
        return false
    }
    guard let first = (destinations.firstObject as? NSNumber)?.uintValue else {
        return false
    }
    let sendMethod = unsafeBitCast(action.method(for: sendSelector),
                                   to: SendResponseForDestination.self)
    return sendMethod(action, sendSelector, first)
}
