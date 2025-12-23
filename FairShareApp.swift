//
//  FairShareApp.swift
//  FairShare
//
//  Created on iOS 18+
//

import SwiftUI
import GoogleSignIn

@main
struct FairShareApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configure Google Sign-In
        let clientId = "232244363828-poj3iprncch67aoi800uptrasgel2qjc.apps.googleusercontent.com"
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

