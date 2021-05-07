//
//  LoginView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

// This is a variation of the tutorial found here: https://www.iosapptemplates.com/blog/swiftui/login-screen-swiftui

import SwiftUI
import ParseSwift
import UIKit

struct LoginView: View {
    
    //Anything is @ is a wrapper that subscribes and refreshes the view when a change occurs.
    @ObservedObject private var login = Login()
    @State private var presentMainScreen = false
    
    var body: some View {

        if login.isLoggedIn {
            MainView(profileModel: login.profileModel)
        } else {

            VStack() {

                //Notice that "action" is a closure (which is essentially a function as an argument)
                Button(action: {
                    login.loginAnonymously()

                }, label: {
                    Text("Login Anonymously")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
                .background(Color(.lightGray))
                .cornerRadius(15)
                //If error occurs show it on the screen
                if let error = login.loginError {
                    Text("Error: \(error.message)")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
