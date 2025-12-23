//
//  HomeViewModel.swift
//  FairShare
//
//  Home screen view model
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentReceipts: [Receipt] = []
    
    private let storageService = StorageService.shared
    
    init() {
        loadRecentReceipts()
    }
    
    func loadRecentReceipts() {
        recentReceipts = storageService.loadReceipts()
    }
    
    func refreshReceipts() {
        loadRecentReceipts()
    }
}

