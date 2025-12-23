//
//  StorageService.swift
//  FairShare
//
//  Service for storing and retrieving receipts and user preferences
//

import Foundation

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private let receiptsKey = "storedReceipts"
    private let currencyKey = "userCurrency"
    
    private init() {}
    
    // MARK: - Receipts Storage
    
    func saveReceipt(_ receipt: Receipt) {
        var receipts = loadReceipts()
        receipts.insert(receipt, at: 0) // Add to beginning
        
        // Keep only last 5 receipts
        if receipts.count > Constants.maxReceiptsToStore {
            receipts = Array(receipts.prefix(Constants.maxReceiptsToStore))
        }
        
        if let encoded = try? JSONEncoder().encode(receipts) {
            UserDefaults.standard.set(encoded, forKey: receiptsKey)
        }
    }
    
    func loadReceipts() -> [Receipt] {
        guard let data = UserDefaults.standard.data(forKey: receiptsKey),
              let receipts = try? JSONDecoder().decode([Receipt].self, from: data) else {
            return []
        }
        return receipts
    }
    
    // MARK: - Currency Preference
    
    func saveCurrency(_ currency: Currency) {
        if let encoded = try? JSONEncoder().encode(currency) {
            UserDefaults.standard.set(encoded, forKey: currencyKey)
        }
    }
    
    func loadCurrency() -> Currency {
        guard let data = UserDefaults.standard.data(forKey: currencyKey),
              let currency = try? JSONDecoder().decode(Currency.self, from: data) else {
            return .egp // Default
        }
        return currency
    }
}

