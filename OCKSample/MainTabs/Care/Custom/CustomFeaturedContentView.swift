//
//  CustomFeaturedContentView.swift
//  OCKSample
//
//  Created by Corey Baker on 5/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKit
import CareKitUI

/// A simple subclass to take control of what CareKit already gives us.
class CustomFeaturedContentView: OCKFeaturedContentView {
    override init(imageOverlayStyle: UIUserInterfaceStyle = .unspecified) {
        super.init(imageOverlayStyle: imageOverlayStyle)
        
        //Need to become a delegate so we know when view is tapped.
        self.delegate = self
    }
}

/// Need to conform to delegate in order to be delegated to.
extension CustomFeaturedContentView: OCKFeaturedContentViewDelegate {
    //ToDo: Make this either open up a link relevant to your app or do something different when tapped.
    //It cannot be the same is what is already happening.
    func didTapView(_ view: OCKFeaturedContentView) {
        //When tapped, open a URL.
        if let url = URL(string: "https://uknowledge.uky.edu/cgi/viewcontent.cgi?article=1008&context=nutrisci_etds") {
            UIApplication.shared.open(url)
        }
    }
}
