//
//  UserDefaultsStorageService.swift
//  Cheq
//
//  UserDefaults implementation of StorageServiceProtocol
//

import Foundation

final class UserDefaultsStorageService: StorageServiceProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Receipts Storage
    
    func saveReceipt(_ receipt: Receipt, userId: String) async throws {
        let saveStartTime = Date()
        print("💾 UserDefaultsStorageService: Starting save for receipt \(receipt.id)")
        print("   Receipt has \(receipt.items.count) items, \(receipt.people.count) people")
        print("   Total: \(receipt.total), Timestamp: \(receipt.timestamp)")
        
        let key = receiptsKey(for: userId)
        
        // Load existing receipts
        var receipts = try await loadAllReceipts(userId: userId)
        
        // Remove existing receipt with same ID if present
        receipts.removeAll { $0.id == receipt.id }
        
        // Add updated receipt
        receipts.append(receipt)
        
        // Sort by timestamp (newest first)
        receipts.sort { $0.timestamp > $1.timestamp }
        
        // Save to UserDefaults
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(receipts)
        userDefaults.set(data, forKey: key)
        
        let totalDuration = Date().timeIntervalSince(saveStartTime)
        print("✅ UserDefaultsStorageService: Receipt saved successfully (took \(String(format: "%.3f", totalDuration))s)")
    }
    
    func loadAllReceipts(userId: String) async throws -> [Receipt] {
        let loadStartTime = Date()
        print("📖 UserDefaultsStorageService: Loading receipts for user \(userId)")
        
        let key = receiptsKey(for: userId)
        
        guard let data = userDefaults.data(forKey: key) else {
            print("📖 UserDefaultsStorageService: No receipts found for user \(userId)")
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let receipts = try decoder.decode([Receipt].self, from: data)
        
        let totalDuration = Date().timeIntervalSince(loadStartTime)
        print("📖 UserDefaultsStorageService: Loaded \(receipts.count) receipts (took \(String(format: "%.3f", totalDuration))s)")
        
        return receipts
    }
    
    func deleteReceipt(_ receiptId: UUID, userId: String) async throws {
        print("🗑️ UserDefaultsStorageService: Deleting receipt \(receiptId) for user \(userId)")
        
        let key = receiptsKey(for: userId)
        
        // Load existing receipts
        var receipts = try await loadAllReceipts(userId: userId)
        
        // Remove receipt
        receipts.removeAll { $0.id == receiptId }
        
        // Save back to UserDefaults
        if receipts.isEmpty {
            userDefaults.removeObject(forKey: key)
        } else {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(receipts)
            userDefaults.set(data, forKey: key)
        }
        
        print("✅ UserDefaultsStorageService: Receipt deleted successfully")
    }
    
    // MARK: - Currency Preference
    
    func saveCurrency(_ currency: Currency) async throws {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(currency) {
            userDefaults.set(data, forKey: currencyKey)
        }
    }
    
    func loadCurrency() async throws -> Currency {
        guard let data = userDefaults.data(forKey: currencyKey),
              let currency = try? JSONDecoder().decode(Currency.self, from: data) else {
            return .egp // Default
        }
        return currency
    }
    
    // MARK: - Helper Methods
    
    private func receiptsKey(for userId: String) -> String {
        return "receipts_\(userId)"
    }
    
    private let currencyKey = "userCurrency"
}
