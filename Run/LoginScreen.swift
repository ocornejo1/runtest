//
//  LoginScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var emailError: String?
    @State private var passwordError: String?

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: email) { _, newValue in
                        validateEmailField(newValue)
                    }
                
                if let error = emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: password) { _, newValue in
                        validatePasswordField(newValue)
                    }
                
                if let error = passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Button("Sign In") {
                signIn()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSignIn ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!canSignIn)

            Button("Create Account") {
                createAccount()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canCreateAccount ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!canCreateAccount)

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Validation
    
    private func validateEmailField(_ value: String) {
        if value.isEmpty {
            emailError = nil
            return
        }
        
        let isValid = ValidationUtilities.validateEmail(value)
        emailError = isValid ? nil : "Invalid email format"
    }
    
    private func validatePasswordField(_ value: String) {
        if value.isEmpty {
            passwordError = nil
            return
        }
        
        let result = ValidationUtilities.validatePassword(value)
        passwordError = result.isValid ? nil : result.message
    }
    
    private var canSignIn: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        emailError == nil
    }
    
    private var canCreateAccount: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        emailError == nil &&
        passwordError == nil
    }

    // MARK: - Actions
    
    private func signIn() {
        showError = false
        errorMessage = ""
        
        authViewModel.signIn(email: email, password: password) { success, error in
            if let error = error {
                showError = true
                errorMessage = userFriendlyAuthError(error)
            }
        }
    }

    private func createAccount() {
        showError = false
        errorMessage = ""
        
        let emailValidation = ValidationUtilities.validateEmail(email)
        let passwordValidation = ValidationUtilities.validatePassword(password)
        
        guard emailValidation else {
            showError = true
            errorMessage = "Invalid email"
            return
        }
        
        guard passwordValidation.isValid else {
            showError = true
            errorMessage = passwordValidation.message ?? "Invalid password"
            return
        }
        
        authViewModel.signUp(email: email, password: password) { success, error in
            if let error = error {
                showError = true
                errorMessage = userFriendlyAuthError(error)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func userFriendlyAuthError(_ error: String) -> String {
        if error.contains("invalid-email") || error.contains("badly formatted") {
            return "Please enter a valid email address"
        } else if error.contains("wrong-password") {
            return "Incorrect password. Please try again."
        } else if error.contains("user-not-found") {
            return "No account found with this email. Try creating an account."
        } else if error.contains("email-already-in-use") {
            return "This email is already registered. Try signing in instead."
        } else if error.contains("weak-password") {
            return "Password must be at least 8 characters"
        } else if error.contains("network") {
            return "Network error. Please check your connection."
        } else if error.contains("too-many-requests") {
            return "Too many attempts. Please try again later."
        } else {
            return error
        }
    }
}
