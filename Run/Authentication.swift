//
//  Authentication.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation
import SwiftUI
import FirebaseAuth

import SwiftUI

struct AuthGate: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.user == nil {
            LoginScreen()
        } else if authViewModel.needsProfile {
            OnboardingSurveyScreen()
        } else {
            ContentView()
        }
    }
}
