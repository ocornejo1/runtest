//
//  RunApp.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI
import Firebase

@main
struct RunApp: App {
    @StateObject private var authVm = AuthViewModel()
    @StateObject private var profileVm = ProfileViewModel()
    init(){
        FirebaseApp.configure()
        
    }
    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environmentObject(authVm)
                .environmentObject(profileVm)
        }
    }
}

