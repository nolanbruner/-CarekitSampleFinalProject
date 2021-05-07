//
//  CustomInstructionsTaskViewController.swift
//  OCKSample
//
//  Created by Corey Baker on 5/5/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import UIKit
import CareKit
import CareKitStore
import CareKitUI

/// A custom version of OCKInstructionsTaskViewController that allows adding a detail image and instruction.
/// You can customize any Card CareKit gives you by subclassing it.
class CustomInstructionsTaskViewController: OCKInstructionsTaskViewController {

    /// A filename from your asset catalog.
    var detailImageFileName = ""

    /// String representations of HTML and CSS for styling.
    var detailHTML = OCKDetailView.StyledHTML(html: "")

    // Can add images and description by overriding this method
    override func didSelectTaskView(_ taskView: UIView & OCKTaskDisplayable, eventIndexPath: IndexPath) {
        do {
            let detailsViewController = try controller.initiateDetailsViewController(forIndexPath: eventIndexPath)
            detailsViewController.detailView.imageView.image = UIImage(named: detailImageFileName)
            detailsViewController.detailView.html = detailHTML
            present(detailsViewController, animated: true)
        } catch {
            if delegate == nil {
                print("CareKit error: A task error occurred, but no delegate was set to forward it to! \(error)")
            }
            delegate?.taskViewController(self, didEncounterError: error)
        }
    }
}
