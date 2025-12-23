//
//  SettingsView.swift
//  FairShare
//
//  Settings screen with profile and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCurrency: Currency = StorageService.shared.loadCurrency()
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile section
                Section("Profile") {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(user.name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Preferences section
                Section("Preferences") {
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.rawValue)").tag(currency)
                        }
                    }
                    .onChange(of: selectedCurrency) { _, newCurrency in
                        StorageService.shared.saveCurrency(newCurrency)
                    }
                }
                
                // Account section
                Section {
                    Button(role: .destructive, action: {
                        showLogoutAlert = true
                    }) {
                        Text("Log Out")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

