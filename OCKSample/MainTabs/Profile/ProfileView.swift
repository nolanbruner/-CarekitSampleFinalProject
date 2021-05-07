//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitUI
import CareKitStore
import CareKit

struct ProfileView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileViewModel: Profile
    @State private var isLoggedOut = false
    @State var firstName = ""
    @State var lastName = ""
    @State var note = ""
    @State var sex = OCKBiologicalSex.female
    @State private var sexOtherField = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipcode = ""
    @State var birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date())!

    @State private var tintColor = UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1) : #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) }
    @State private var isShowingImagePicker = false
    @State private var action: Int? = 0
    
    var body: some View {
        //A NavigationView is needed to use Picker
        NavigationView {
            VStack {
                NavigationLink(destination: MyContactView(), tag: 1, selection: $action) {
                    EmptyView()
                }
                if let image = profileViewModel.profilePicture {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .overlay(Circle().stroke(Color(tintColor), lineWidth: 5))
                        .onTapGesture {
                            self.isShowingImagePicker = true
                        }
                } else {
                    Image("ProfileIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .overlay(Circle().stroke(Color(tintColor), lineWidth: 5))
                        .onTapGesture {
                            self.isShowingImagePicker = true
                        }
                }

                Form {
                    Section(header: Text("About")) {
                        TextField("First Name", text: $firstName)
                        TextField("Last Name", text: $lastName)
                        TextField("Note", text: $note)
                        DatePicker("Birthday", selection: $birthday, displayedComponents: [DatePickerComponents.date])
                        
                        Picker(selection: $sex, label: Text("Sex"), content: {
                            Text(OCKBiologicalSex.female.rawValue).tag(OCKBiologicalSex.female)
                            Text(OCKBiologicalSex.male.rawValue).tag(OCKBiologicalSex.male)
                            TextField("Other", text: $sexOtherField).tag(OCKBiologicalSex.other(sexOtherField))
                        })
                    }
                    
                    Section(header: Text("Contact")) {
                        TextField("Street", text: $street)
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                        TextField("Postal code", text: $zipcode)
                    }
                    //Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
                    Button(action: {

                        profileViewModel.saveProfile(firstName, last: lastName, birth: birthday, sex: sex, note: note, street: street, city: city, state: state, zipcode: zipcode)

                    }, label: {
                        
                        Text("Save Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 50)
                    })
                    .background(Color(.green))
                    .cornerRadius(15)
                    
                    if #available(iOS 14.0, *) {
                        
                        //Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
                        Button(action: {
                            do {
                                try profileViewModel.logout()
                                isLoggedOut = true
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                print("Error logging out: \(error)")
                            }
                            
                        }, label: {
                            
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 300, height: 50)
                        })
                        .background(Color(.red))
                        .cornerRadius(15)
                        .fullScreenCover(isPresented: $isLoggedOut, content: {
                            LoginView()
                        })
                    } else {
                        // Fallback on earlier versions
                        Button(action: {
                            do {
                                try profileViewModel.logout()
                                isLoggedOut = true
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                print("Error logging out: \(error)")
                            }
                            
                        }, label: {
                            
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 300, height: 50)
                        })
                        .background(Color(.red))
                        .cornerRadius(15)
                        .sheet(isPresented: $isLoggedOut, content: {
                            LoginView()
                        })
                    }
                }
            }.navigationBarItems(trailing:
                Button(action: {
                    self.action = 1
                }) {
                    Text("My Contact")
                })
        }.onReceive(profileViewModel.$patient, perform: { patient in
            if let currentFirstName = patient?.name.givenName {
                firstName = currentFirstName
            }
            
            if let currentLastName = patient?.name.familyName {
                lastName = currentLastName
            }
            
            if let currentBirthday = patient?.birthday {
                birthday = currentBirthday
            }

            if let currentNote = patient?.notes?.first?.content {
                note = currentNote
            }

            if let currentSex = patient?.sex {
                sex = currentSex
            }
        }).onReceive(profileViewModel.$contact, perform: { contact in
            if let currentStreet = contact?.address?.street {
                street = currentStreet
            }
            if let currentCity = contact?.address?.city {
                city = currentCity
            }
            if let currentState = contact?.address?.state {
                state = currentState
            }
            if let currentZipcode = contact?.address?.postalCode {
                zipcode = currentZipcode
            }
        }).onAppear(perform: {
            profileViewModel.load()
        }).sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$profileViewModel.profilePicture)
        }.alert(isPresented: $profileViewModel.isShowingSaveAlert) {
            return Alert(title: Text("Update"),
                         message: Text("All changs saved successfully!"),
                         dismissButton: .default(Text("Ok"), action: {
                            profileViewModel.isShowingSaveAlert = false
                            self.presentationMode.wrappedValue.dismiss()
                         }))
        }
    }

    func loadImage() {
        guard let _ = profileViewModel.profilePicture else { return }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(profileViewModel: Profile())
    }
}
