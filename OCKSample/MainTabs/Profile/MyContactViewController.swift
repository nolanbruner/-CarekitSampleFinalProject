//
//  MyContactViewController.swift
//  OCKSample
//
//  Created by Corey Baker on 5/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import CareKit
import Contacts
import ContactsUI
import ParseSwift
import ParseCareKit

class MyContactViewController: OCKListViewController {

    fileprivate weak var contactDelegate: OCKContactViewControllerDelegate?
    fileprivate var allContacts = [OCKAnyContact]()
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchMyContact()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchMyContact()
    }

    func displayContacts(_ contacts: [OCKAnyContact]){
        for contact in contacts {
            guard let synchronizedStoreManager = self.appDelegate.synchronizedStoreManager else {
                return
            }
            let contactViewController = OCKDetailedContactViewController(contact: contact, storeManager: synchronizedStoreManager)
            contactViewController.delegate = self.contactDelegate
            self.appendViewController(contactViewController, animated: false)
        }
    }

    func fetchMyContact() {
        //ToDo to get credit: How would you modify this query to only fetch the contact that belongs to this device?
        var query = OCKContactQuery(for: Date())
        query.sortDescriptors.append(.familyName(ascending: true))
        query.sortDescriptors.append(.givenName(ascending: true))
        
        appDelegate.coreDataStore.fetchAnyContacts(query: query, callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print(error)
            case .success(let contacts):
                /*Hint 1: it has something to do with this line. If you do it correctly, this guard statement isn't need here.
                 You will still need:
                 guard let convertedContacts = contacts as? [OCKContact] else{
                     return
                 }
                 */
                //Hint2: Look at the other queries in the app related to the uuid of the user who's signed in.
                guard User.current != nil,
                      let personUUIDString = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String,
                    let convertedContacts = contacts as? [OCKContact] else{
                    return
                }
                self.clearContents()
                self.allContacts = convertedContacts
                self.displayContacts(self.allContacts)
            }
        }
    }

    func clearContents(){
        clear()
    }
}
