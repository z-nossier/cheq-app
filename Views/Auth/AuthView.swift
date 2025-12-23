//
//  AuthView.swift
//  FairShare
//
//  Authentication screen with Google Sign-In
//

import SwiftUI
import GoogleSignIn

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "square.split.2x2")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FairShare")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Text("Split your bills fair & square")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        GoogleSignInButton(action: {
                            authViewModel.signIn()
                        })
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "globe")
                    .font(.title3)
                Text("Continue with Google")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .frame(minHeight: Constants.minimumTapTargetSize)
    }
}

