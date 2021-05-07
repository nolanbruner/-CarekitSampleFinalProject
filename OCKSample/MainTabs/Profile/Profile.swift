//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import SwiftUI
import ParseCareKit
import UIKit
import ParseSwift

class Profile: ObservableObject {
    
    @Published var patient: OCKPatient? = nil
    @Published var sex: OCKBiologicalSex = .female
    @Published var contact: OCKContact? = nil
    @Published var isShowingSaveAlert = false
    @Published var profilePicture = UIImage(systemName: "person.crop.circle") {
        willSet {
            if !settingProfilePicForFirstTime {
                guard var user = User.current,
                      let image = newValue?.jpegData(compressionQuality: 0.25) else{
                    return
                }
                
                let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
                user.profilePicture = newProfilePicture
                user.save { result in
                    switch result {
                    
                    case .success:
                        print("Saved updated profile picture successfully.")
                    case .failure(let error):
                        print("Error saving profile picture: \(error)")
                    }
                }
            }
        }
    }
    private var settingProfilePicForFirstTime = true
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate //Importing UIKit gives us access here to get the OCKStore and ParseRemote
    
    init() {
        load()
    }

    func load() {
        //Find this patient
        findCurrentProfile { foundPatient in
            self.patient = foundPatient
        }

        //Find this contact
        findCurrentContact { foundContact in
            self.contact = foundContact
        }

        fetchProfilePic()
    }

    private func fetchProfilePic() {
        //Profile pics are stored in Parse User.
        User.current?.fetch { result in
            switch result {
            
            case .success(let user):
                if let pictureFile = user.profilePicture {
                    //Download picture from server
                    pictureFile.fetch { pictureResult in
                        switch pictureResult {
                        
                        case .success(let profilePic):
                            guard let path = profilePic.localURL?.relativePath else {
                                return
                            }
                            self.profilePicture = UIImage(contentsOfFile: path)
                        case .failure(let error):
                            print("Error fetching profile picture: \(error).")
                        }
                        self.settingProfilePicForFirstTime = false
                    }
                } else {
                    self.settingProfilePicForFirstTime = false
                }
                    
            case .failure(let error):
                print("Error fetching user: \(error).")
            }
        }
    }
    
    private func findCurrentProfile(completion: @escaping (OCKPatient?)-> Void) {
        
        guard let uuid = getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            completion(nil)
            return
        }

        //Build query to search for OCKPatient
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) //This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] //Search for the current logged in user
        
        self.appDelegate.synchronizedStoreManager?.store.fetchAnyPatients(query: queryForCurrentPatient, callbackQueue: .main) { result in
            switch result {
            
            case .success(let foundPatient):
                guard let currentPatient = foundPatient.first as? OCKPatient else {
                    completion(nil)
                    return
                }
                completion(currentPatient)
                
            case .failure(let error):
                print("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error)")
                completion(nil)
            }
        }
    }

    private func findCurrentContact(completion: @escaping (OCKContact?)-> Void) {
        
        guard let uuid = getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            completion(nil)
            return
        }

        //Build query to search for OCKPatient
        var queryForCurrentContact = OCKContactQuery(for: Date()) //This makes the query for the current version of Patient
        queryForCurrentContact.ids = [uuid.uuidString] //Search for the current logged in user
        
        self.appDelegate.synchronizedStoreManager?.store.fetchAnyContacts(query: queryForCurrentContact, callbackQueue: .main) { result in
            switch result {
            
            case .success(let foundContact):
                guard let currentContact = foundContact.first as? OCKContact else {
                    completion(nil)
                    return
                }
                completion(currentContact)
                
            case .failure(let error):
                print("Error: Couldn't find contact with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error)")
                completion(nil)
            }
        }
    }

    //Mark: User intentions
    
    func saveProfile(_ first: String, last: String, birth: Date, sex: OCKBiologicalSex, note: String, street: String, city: String, state: String, zipcode: String) {
        
        isShowingSaveAlert = true //Make alert pop up

        if var patientToUpdate = patient {
            //If there is a currentPatient that was fetched, check to see if any of the fields changed
            
            var patientHasBeenUpdated = false
            
            if patient?.name.givenName != first {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = first
            }
            
            if patient?.name.familyName != last {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = last
            }
            
            if patient?.birthday != birth {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birth
            }

            if patient?.sex != sex {
                patientHasBeenUpdated = true
                patientToUpdate.sex = sex
            }
            
            let notes = [OCKNote(author: first, title: "my note", content: note)]
            if patient?.notes != notes {
                patientHasBeenUpdated = true
                patientToUpdate.notes = notes
            }

            if patientHasBeenUpdated {
                appDelegate.synchronizedStoreManager?.store.updateAnyPatient(patientToUpdate, callbackQueue: .main) { result in
                    switch result {
                    
                    case .success(let updated):
                        print("Successfully updated patient")
                        guard let updatedPatient = updated as? OCKPatient else {
                            return
                        }
                        self.patient = updatedPatient
                    case .failure(let error):
                        print("Error updating patient: \(error)")
                    }
                }
            }
            
        } else {
            
            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
                print("Error: The user currently isn't logged in")
                return
            }
            
            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth
            
            //This is new patient that has never been saved before
            appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient, callbackQueue: .main) { result in
                switch result {
                
                case .success(let new):
                    print("Succesffully saved new patient")
                    guard let newPatient = new as? OCKPatient else {
                        return
                    }
                    self.patient = newPatient
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }

        if var contactToUpdate = contact {
            //If there is a currentPatient that was fetched, check to see if any of the fields changed
            
            var contactHasBeenUpdated = false
            
            //Since OCKPatient was updated earlier, we should compare against this name
            if let patientName = patient?.name,
                contact?.name != patient?.name {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
            }

            //Create a mutable temp address to compare
            let potentialAddress = OCKPostalAddress()
            potentialAddress.street = street
            potentialAddress.city = city
            potentialAddress.state = state
            potentialAddress.postalCode = zipcode

            if contact?.address != potentialAddress {
                contactHasBeenUpdated = true
                contactToUpdate.address = potentialAddress
            }

            if contactHasBeenUpdated {
                appDelegate.synchronizedStoreManager?.store.updateAnyContact(contactToUpdate, callbackQueue: .main) { result in
                    switch result {
                    
                    case .success(let updated):
                        print("Successfully updated contact")
                        guard let updatedContact = updated as? OCKContact else {
                            return
                        }
                        self.contact = updatedContact
                    case .failure(let error):
                        print("Error updating contact: \(error)")
                    }
                }
            }
            
        } else {
            
            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String,
                  let patientName = patient?.name else {
                print("Error: The user currently isn't logged in")
                return
            }
            
            let newContact = OCKContact(id: remoteUUID, name: patientName, carePlanUUID: nil)
            
            //This is new patient that has never been saved before
            appDelegate.synchronizedStoreManager?.store.addAnyContact(newContact, callbackQueue: .main) { result in
                switch result {
                
                case .success(let new):
                    print("Succesffully saved new patient")
                    guard let newContact = new as? OCKContact else {
                        return
                    }
                    self.contact = newContact
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func savePatientAfterSignUp(_ first: String, last: String, completion: @escaping (Result<OCKPatient,Error>) -> Void) {
        
        let remoteUUID = UUID()
        
        //Because of the app delegate access above, we can place the initial data in the database
        self.appDelegate.setupRemotes(uuid: remoteUUID)
        self.appDelegate.coreDataStore.populateSampleData()
        self.appDelegate.healthKitStore.populateSampleData()
        self.appDelegate.parse.automaticallySynchronizes = true
        self.appDelegate.firstLogin = true
        
        //Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                if error != nil {
                    print(error!.localizedDescription)
                }
            }
        }
        
        //Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()
        
        var newPatient = OCKPatient(id: remoteUUID.uuidString, givenName: first, familyName: last)
        newPatient.userInfo = [Constants.parseRemoteClockIDKey: remoteUUID.uuidString] //Save the remoteId String
        
        appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient, callbackQueue: .main) { result in
            switch result {
            
            case .success(let savedPatient):
                
                guard let patient = savedPatient as? OCKPatient else {
                    completion(.failure(AppError.couldntCast))
                    return
                }
                self.patient = patient
                
                //Create a new Contact on signup as well
                let newContact = OCKContact(id: remoteUUID.uuidString, givenName: first, familyName: last, carePlanUUID: nil)
                self.appDelegate.synchronizedStoreManager?.store.addAnyContact(newContact, callbackQueue: .main) { result in
                    switch result {
                    
                    case .success(let savedContact):
                        
                        guard let contact = savedContact as? OCKContact else {
                            return
                        }
                        self.contact = contact
                        
                        print("Successfully added a new Contact")
                    case .failure(let error):
                        print("Error adding Contact: \(error)")
                    }
                }

                print("Successfully added a new Patient")
                completion(.success(patient))
            case .failure(let error):
                print("Error adding Patient: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }
        
        return UUID(uuidString: uuid)
    }
    
    func getRemoteClockUUIDAfterLoginFromCloud(completion: @escaping (Result<UUID,Error>) -> Void) {
        
        let query = Patient.query()
        
        query.first(callbackQueue: .main) { result in
            switch result {
            
            case .success(let patient):
                guard let uuid = patient.userInfo?[Constants.parseRemoteClockIDKey],
                      let remoteClockId = UUID(uuidString: uuid) else {
                    completion(.failure(AppError.valueNotFoundInUserInfo))
                    return
                }
                completion(.success(remoteClockId))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setupRemoteAfterLoginButtonTapped(completion: @escaping (Result<UUID,Error>) -> Void) {
        
        getRemoteClockUUIDAfterLoginFromCloud { result in
            switch result {
            
            case .success(let uuid):
                
                DispatchQueue.main.async {
                    self.appDelegate.setupRemotes(uuid: uuid)
                    self.appDelegate.parse.automaticallySynchronizes = true
                    self.appDelegate.firstLogin = true
                    
                    //Save remote ID to local
                    UserDefaults.standard.setValue(uuid.uuidString, forKey: Constants.parseRemoteClockIDKey)
                    UserDefaults.standard.synchronize()
                    
                    NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                            if error != nil {
                                print(error!.localizedDescription)
                            }
                        }
                    }
                    
                    completion(.success(uuid))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //You may not have seen "throws" before, but it's simple, this throws an error if one occurs, if not it behaves as normal
    //Normally, you've seen do {} catch{} which catches the error, same concept...
    func logout() throws {
        try User.logout()
        UserDefaults.standard.removeObject(forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        try appDelegate.healthKitStore.reset()
        try appDelegate.coreDataStore.delete() //Delete data in local OCKStore database
    }
}

//Needed to use OCKBiologicalSex in a Picker.
//Simple conformance to hashable protocol.
extension OCKBiologicalSex: Hashable { }
