//
//  AuthViewModel.swift
//  Run
//
//  Created by Omar Cornejo.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var needsProfile = false

    private let db = Firestore.firestore()

    init() {
        user = Auth.auth().currentUser

        if let uid = user?.uid {
            fetchProfileStatus(for: uid)
        }
    }

    private func fetchProfileStatus(for uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.needsProfile = true
                }
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                let completed = snapshot.data()?["completedOnboarding"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.needsProfile = !completed
                }
            } else {
                DispatchQueue.main.async {
                    self.needsProfile = true
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                self.user = result?.user
                if let uid = result?.user.uid {
                    self.fetchProfileStatus(for: uid)
                }
                completion(true, nil)
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else if let user = result?.user {
                self.user = user
                DispatchQueue.main.async {
                    self.needsProfile = true
                }
                completion(true, nil)
            }
        }
    }

    func markProfileCompleted() {
        DispatchQueue.main.async {
            self.needsProfile = false
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.needsProfile = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
