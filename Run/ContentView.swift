//
//  ContentView.swift
//  Run
//
//  Created by Omar Cornejo
//
import SwiftUI

struct ContentView: View {
    @StateObject private var profileVM = ProfileViewModel()
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            MapScreen()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Run")
                }

            EducationScreen(level: profileVM.profile?.experienceLevel ?? .beginner)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Training")
                }

            RunHistoryScreen(unit:profileVM.profile?.distanceUnit ?? .kilometers)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }

            SettingsScreen()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        
        .onAppear {
            profileVM.loadProfile()
        }
        
        .environmentObject(profileVM)
    }
}


