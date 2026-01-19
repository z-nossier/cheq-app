//
//  StorageService.swift
//  Cheq
//
//  Service for storing and retrieving receipts and user preferences
//

import Foundation

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private let backend: StorageServiceProtocol
    
    private init() {
        // Initialize UserDefaults backend
        self.backend = UserDefaultsStorageService()
    }
    
    // MARK: - Receipts Storage
    
    /// Saves a receipt for a specific user. Stores all receipts (no limit).
    func saveReceipt(_ receipt: Receipt, userId: String) {
        print("💾 StorageService: Starting save for receipt \(receipt.id), user \(userId)")
        Task {
            do {
                try await backend.saveReceipt(receipt, userId: userId)
                print("✅ StorageService: Successfully saved receipt \(receipt.id)")
            } catch {
                print("❌ StorageService: Error saving receipt \(receipt.id): \(error.localizedDescription)")
                print("   Full error: \(error)")
            }
        }
    }
    
    /// Saves a receipt for a specific user (async version that can be awaited).
    func saveReceiptAsync(_ receipt: Receipt, userId: String) async throws {
        print("💾 StorageService: Starting async save for receipt \(receipt.id), user \(userId)")
        try await backend.saveReceipt(receipt, userId: userId)
        print("✅ StorageService: Successfully saved receipt \(receipt.id)")
    }
    
    /// Loads all receipts for a specific user (async version)
    func loadAllReceipts(userId: String) async throws -> [Receipt] {
        return try await backend.loadAllReceipts(userId: userId)
    }
    
    /// Loads all receipts for a specific user (synchronous version - deprecated, use async version)
    @available(*, deprecated, message: "Use async loadAllReceipts instead")
    func loadAllReceiptsSync(userId: String) -> [Receipt] {
        // For synchronous access, use a semaphore to wait for async operation
        let semaphore = DispatchSemaphore(value: 0)
        var receipts: [Receipt] = []
        
        Task {
            do {
                receipts = try await backend.loadAllReceipts(userId: userId)
            } catch {
                print("Error loading receipts: \(error)")
                receipts = []
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return receipts
    }
    
    /// Loads receipts for a specific user (for backward compatibility, same as loadAllReceipts)
    func loadReceipts(userId: String) async throws -> [Receipt] {
        return try await loadAllReceipts(userId: userId)
    }
    
    /// Deletes a receipt for a specific user
    func deleteReceipt(_ receiptId: UUID, userId: String) async throws {
        try await backend.deleteReceipt(receiptId, userId: userId)
    }
    
    /// Deletes all receipts for a specific user
    func deleteAllReceipts(userId: String) async throws {
        let receipts = try await loadAllReceipts(userId: userId)
        for receipt in receipts {
            try await deleteReceipt(receipt.id, userId: userId)
        }
    }
    
    // MARK: - Currency Preference
    
    func saveCurrency(_ currency: Currency) {
        Task {
            do {
                try await backend.saveCurrency(currency)
            } catch {
                print("Error saving currency: \(error)")
            }
        }
    }
    
    func loadCurrency() -> Currency {
        // For synchronous access, use a semaphore to wait for async operation
        let semaphore = DispatchSemaphore(value: 0)
        var currency: Currency = .egp
        
        Task {
            do {
                currency = try await backend.loadCurrency()
            } catch {
                print("Error loading currency: \(error)")
                currency = .egp
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return currency
    }
}

