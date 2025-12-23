//
//  SummaryViewModel.swift
//  FairShare
//
//  Summary view model
//

import Foundation
import Combine
import UIKit

@MainActor
class SummaryViewModel: ObservableObject {
    @Published var splits: [PersonSplit] = []
    
    private let calculationService = CalculationService.shared
    private let storageService = StorageService.shared
    
    init(receipt: Receipt) {
        calculateSplits(for: receipt)
    }
    
    func calculateSplits(for receipt: Receipt) {
        splits = calculationService.calculateSplits(for: receipt)
        
        // Save receipt
        storageService.saveReceipt(receipt)
        
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func generateShareText(currency: Currency) -> String {
        var text = "FairShare Summary:\n\n"
        
        for split in splits {
            let amount = split.finalAmount.formatted(currency: currency)
            text += "\(split.person.name) owes \(amount)\n"
        }
        
        text += "\nSplit fairly, not evenly! 🎉"
        return text
    }
}

