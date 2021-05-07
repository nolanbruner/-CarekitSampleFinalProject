//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseSwift
import CareKit
import CareKitStore

class Login: ObservableObject {

    private(set) var isLoggedIn = false {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    private(set) var loginError: ParseError? = nil {
        willSet {
            objectWillChange.send() //Publishes a notification to subscribers whenever this value changes
        }
    }
    private(set) var profileModel: Profile!
    
    //MARK: User intentional behavier

    /**
     Logs in the user anonymously *asynchronously*.
    */
    func loginAnonymously() {
        
        User.anonymous.login { result in

            switch result {
            
            case .success(let user):
                print("Parse login successful: \(user)")
                    
                self.profileModel = Profile()
                self.profileModel?.savePatientAfterSignUp("Anonymous", last: "Login") { result in
                    switch result {
                    
                    case .success(_):
                        self.isLoggedIn = true //Notify the SwiftUI view that the user is correctly logged in and to transition screens
                        
                        //Setup installation to receive push notifications
                        Installation.current?.save() { result in
                            switch result {
                            
                            case .success(_):
                                print("Parse Installation saved, can now receive push notificaitons.")
                            case .failure(let error):
                                print("Error saving Parse Installation saved: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Error saving the patient after signup: \(error)")
                    }
                }
                
            case .failure(let error):
                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                print("Parse error: \(String(describing: error))")
                
                self.loginError = error //Notify the SwiftUI view that there's an error
            }
        }
    }
}

