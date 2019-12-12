//
//  FirebaseAuthManager.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/10.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://www.iosapptemplates.com/blog/swift-programming/firebase-swift-tutorial-login-registration-ios
// 2. https://medium.com/swlh/how-to-authenticate-users-with-firebase-in-swift-40eabfcc0a5f
// 3. https://firebase.google.com/docs/auth/ios/start
// 4. https://stackoverflow.com/questions/57420612/how-to-fix-nw-connection-receive-internal-block-invoke-console

import Foundation
import FirebaseAuth

class FirebaseAuthManager {
    func createUser (email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password){
            (authResult, error) in
            if let error = error {
                print("User created error: ", error)
                completion(false)
            }else{
                print("User \(email) created successfully.")
                completion(true)
            }
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) {
            (authResult, error) in
            if let error = error {
                print("User sign in error: ", error)
                completion(false)
            }else {
                print("User \(email) successfully logged in.")
                completion(true)
            }
        }
        
    }
    
    
}

