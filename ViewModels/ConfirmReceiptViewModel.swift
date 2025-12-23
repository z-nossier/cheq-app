//
//  ConfirmReceiptViewModel.swift
//  FairShare
//
//  Confirm receipt view model
//

import Foundation
import Combine
import UIKit

@MainActor
class ConfirmReceiptViewModel: ObservableObject {
    @Published var receipt: Receipt
    @Published var isValid = false
    @Published var isPreviewMode: Bool
    @Published var previewImage: UIImage?
    @Published var boundingBoxes: [BoundingBox]?
    let ocrResult: OCRResult
    
    private let storageService = StorageService.shared
    
    init(ocrResult: OCRResult, isPreview: Bool = false) {
        self.ocrResult = ocrResult
        self.isPreviewMode = isPreview
        self.previewImage = ocrResult.sourceImage
        self.boundingBoxes = ocrResult.boundingBoxes
        
        let items = ocrResult.items
        let subtotal = ocrResult.subtotal ?? items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        let total = ocrResult.total ?? subtotal
        
        self.receipt = Receipt(
            items: items,
            subtotal: subtotal,
            vatPercentage: ocrResult.vatPercentage ?? 0,
            servicePercentage: ocrResult.servicePercentage ?? 0,
            total: total
        )
        
        updateValidity()
    }
    
    func confirmPreview() {
        isPreviewMode = false
    }
    
    func updateItem(at index: Int, name: String? = nil, unitPrice: Decimal? = nil, quantity: Int? = nil) {
        guard index < receipt.items.count else { return }
        
        if let name = name {
            receipt.items[index].name = name
        }
        if let unitPrice = unitPrice {
            receipt.items[index].unitPrice = unitPrice
        }
        if let quantity = quantity {
            receipt.items[index].quantity = quantity
            receipt.items[index].ensureUnitAssignmentsCount()
        }
        
        recalculateTotals()
    }
    
    func updateVATPercentage(_ percentage: Decimal) {
        receipt.vatPercentage = percentage
        recalculateTotals()
    }
    
    func updateServicePercentage(_ percentage: Decimal) {
        receipt.servicePercentage = percentage
        recalculateTotals()
    }
    
    private func recalculateTotals() {
        receipt.subtotal = receipt.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        receipt.total = receipt.calculatedTotal
        updateValidity()
    }
    
    private func updateValidity() {
        isValid = !receipt.items.isEmpty && receipt.total > 0
    }
}

