//
//  CustomButtonLogTaskViewController.swift
//  OCKSample
//
//  Created by Corey Baker on 5/5/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CareKit
import CareKitUI
import CareKitStore

class CustomButtonLogTaskViewController: OCKButtonLogTaskViewController {
    
    //Need access to local storage
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var selectedEventIndex = IndexPath()
    var logValueViewController: UIHostingController<LogValueView>?

    override func taskView(_ taskView: UIView & OCKTaskDisplayable, didCreateOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        
        //Need to store this index to use later
        self.selectedEventIndex = eventIndexPath
        
        //Setup SwiftUI view as UIKit view
        let logValue = LogValue() //Initialize the view model.
        logValue.delegate = self //Become a delegate of the view model. LogValue when delegate saving and dismissing to this class.
        logValueViewController = LogValueView(viewModel: logValue).customformattedHostingController() //Our view is a SwiftUI view, but we need to use it in UIKit
        
        //Allow the view to be a popover and dismiss with a swipe.
        //Also allows this to work properly on an iPad.
        let presentationController = logValueViewController?.popoverPresentationController
        presentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        presentationController?.sourceRect = self.tabBarController!.tabBar.frame
        presentationController?.sourceView = view
        presentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        //Ensure we have a real controller
        guard let controller = logValueViewController else { return }
        present(controller, animated: true, completion: nil)
    }
}

/// Conform to delegate so we know when to save and dismiss the view.
extension CustomButtonLogTaskViewController: LogValueDelegate {

    func save(_ value: String) {
        guard let event = controller.eventFor(indexPath: self.selectedEventIndex),
              let value = Int(value) else { return }
        
        let newOutcomeValue = OCKOutcomeValue(value)
        
        // Update the outcome with the new value
        if var outcome = event.outcome {
            outcome.values.append(newOutcomeValue)
            appDelegate.coreDataStore.updateAnyOutcome(outcome, callbackQueue: .main) { result in
                print("Updated outcome with \(result)")
            }

        // Else Save a new outcome if one does not exist
        } else {
            do {
                guard let outcome = try controller.makeOutcomeFor(event: event, withValues: [newOutcomeValue]) as? OCKOutcome else{
                    print("Error in SurveyButtonLogViewController.didfinishWith could not cast to OCKOutcome")
                    return
                }

                appDelegate.coreDataStore.addOutcome(outcome, callbackQueue: .main) { result in
                    switch result{
                    case .success(let savedOutcome):
                        print("Saved outcome to CareKit \(savedOutcome)")
                    case .failure(_):
                        print("Error")
                    }
                    print("Saved outcome with result \(result)")
                }
            } catch {
                print(error)
            }
        }
        dismiss()
    }
    
    func dismiss() {
        logValueViewController?.dismiss(animated: true, completion: nil)
    }
}

//This extention only needs to be added to your project once.
extension View {
    func customformattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        return viewController
    }
}
