//
//  AuthViewModel.swift
//  FairShare
//
//  Authentication view model
//

import Foundation
import Combine
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    init() {
        isAuthenticated = authService.isAuthenticated
        currentUser = authService.currentUser
    }
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to access view controller"
            isLoading = false
            return
        }
        
        Task {
            do {
                try await authService.signIn(with: rootViewController)
                isAuthenticated = authService.isAuthenticated
                currentUser = authService.currentUser
                isLoading = false
            } catch {
                errorMessage = "Sign in failed. Please try again."
                isLoading = false
            }
        }
    }
    
    func signOut() {
        authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}

