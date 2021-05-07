//
//  MyContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 5/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import UIKit

struct MyContactView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> some UIViewController {

        let myContact = MyContactViewController()
        let myContactViewController = UINavigationController(rootViewController: myContact)

        return myContactViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

struct MyContactView_Previews: PreviewProvider {
    static var previews: some View {
        MyContactView()
    }
}
