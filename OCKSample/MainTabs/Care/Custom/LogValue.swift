//
//  LogValue.swift
//  OCKSample
//
//  Created by Corey Baker on 5/6/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import UIKit

/// In order to save values, UIKit classes should conform to this protocol and become a delegate.
protocol LogValueDelegate: AnyObject {

    /// Save the value to CareKit store.
    func save(_ value: String)
    
    /// Dismisses the screen.
    func dismiss()
}

/// Simple Class for logging values.
class LogValue: ObservableObject {
    @Published var value = ""
    var delegate: LogValueDelegate?

    /// Save the value to CareKit store.
    func save() {
        delegate?.save(value)
    }

    /// Cancels the selection and ignores the value.
    func cancel() {
        delegate?.dismiss()
    }
}

