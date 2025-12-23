//
//  OCRService.swift
//  FairShare
//
//  OCR service using Apple Vision framework
//

import Foundation
import Vision
import UIKit

struct OCRResult {
    var items: [ReceiptItem]
    var subtotal: Decimal?
    var vatPercentage: Decimal?
    var servicePercentage: Decimal?
    var total: Decimal?
    var boundingBoxes: [BoundingBox]
    var sourceImage: UIImage?
    var detectedRectangle: CGRect?
    
    init(
        items: [ReceiptItem] = [],
        subtotal: Decimal? = nil,
        vatPercentage: Decimal? = nil,
        servicePercentage: Decimal? = nil,
        total: Decimal? = nil,
        boundingBoxes: [BoundingBox] = [],
        sourceImage: UIImage? = nil,
        detectedRectangle: CGRect? = nil
    ) {
        self.items = items
        self.subtotal = subtotal
        self.vatPercentage = vatPercentage
        self.servicePercentage = servicePercentage
        self.total = total
        self.boundingBoxes = boundingBoxes
        self.sourceImage = sourceImage
        self.detectedRectangle = detectedRectangle
    }
}

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func detectRectangles(in image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let rectangles = observations.compactMap { observation -> CGRect? in
                    let boundingBox = observation.boundingBox
                    // Convert normalized coordinates to image coordinates
                    let rect = VNImageRectForNormalizedRect(
                        boundingBox,
                        Int(imageSize.width),
                        Int(imageSize.height)
                    )
                    
                    // Filter by aspect ratio (prefer tall rectangles)
                    let aspectRatio = rect.height / rect.width
                    if aspectRatio < Constants.receiptMinAspectRatio {
                        return nil
                    }
                    
                    // Filter by minimum size
                    let minSize = imageSize.width * Constants.receiptMinSizeRatio
                    if rect.width < minSize || rect.height < minSize {
                        return nil
                    }
                    
                    return rect
                }
                
                continuation.resume(returning: rectangles)
            }
            
            request.minimumAspectRatio = 0.2
            request.maximumAspectRatio = 0.98
            request.minimumSize = 0.1
            request.minimumConfidence = 0.5
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func processImageInRectangle(_ image: UIImage, rect: CGRect) async throws -> (observations: [VNRecognizedTextObservation], confidence: Double) {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        // Crop image to rectangle
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let normalizedRect = VNNormalizedRectForImageRect(rect, Int(imageSize.width), Int(imageSize.height))
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ([], 0.0))
                    return
                }
                
                // Filter observations to only include those within the rectangle
                let filteredObservations = observations.filter { observation in
                    let obsRect = observation.boundingBox
                    return normalizedRect.contains(obsRect)
                }
                
                let confidence = self.calculateConfidenceScore(from: filteredObservations)
                continuation.resume(returning: (filteredObservations, confidence))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.regionOfInterest = normalizedRect
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func calculateConfidenceScore(from observations: [VNRecognizedTextObservation]) -> Double {
        guard !observations.isEmpty else { return 0.0 }
        
        var score = 0.0
        let text = observations.compactMap { $0.topCandidates(1).first?.string ?? "" }.joined(separator: " ")
        let lowercased = text.lowercased()
        
        // Keyword presence (40% weight)
        let keywords = ["total", "subtotal", "tax", "service", "tip", "amount"]
        let keywordCount = keywords.filter { lowercased.contains($0) }.count
        score += Double(keywordCount) / Double(keywords.count) * 0.4
        
        // Price pattern detection (30% weight)
        let pricePattern = #"\$\d+\.\d{2}|\d+\.\d{2}"#
        if let regex = try? NSRegularExpression(pattern: pricePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            let priceCount = matches.count
            score += min(Double(priceCount) / 5.0, 1.0) * 0.3
        }
        
        // Large number near bottom (20% weight)
        // Check last 30% of observations for large numeric value
        let bottomObservations = Array(observations.suffix(max(1, observations.count * 3 / 10)))
        var foundLargeNumber = false
        for observation in bottomObservations {
            if let candidate = observation.topCandidates(1).first {
                let text = candidate.string
                // Look for large numbers (likely total)
                if let regex = try? NSRegularExpression(pattern: #"\d+\.\d{2}"#),
                   let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                   let range = Range(match.range, in: text),
                   let value = Double(String(text[range])),
                   value > 10.0 {
                    foundLargeNumber = true
                    break
                }
            }
        }
        if foundLargeNumber {
            score += 0.2
        }
        
        // Vertical alignment (10% weight)
        // Check if prices align vertically (simplified check)
        let xPositions = observations.map { Float($0.boundingBox.midX) }
        let xVariance = calculateVariance(xPositions)
        // Lower variance means better alignment
        let alignmentScore = max(0, 1.0 - xVariance * 10)
        score += alignmentScore * 0.1
        
        return min(score, 1.0)
    }
    
    private func calculateVariance(_ values: [Float]) -> Double {
        guard !values.isEmpty else { return 1.0 }
        let mean = values.reduce(0, +) / Float(values.count)
        let squaredDiffs = values.map { pow(Double($0 - mean), 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    func processImage(_ image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(
                        items: [],
                        subtotal: nil,
                        vatPercentage: nil,
                        servicePercentage: nil,
                        total: nil,
                        boundingBoxes: [],
                        sourceImage: image,
                        detectedRectangle: nil
                    ))
                    return
                }
                
                let (parsedResult, boundingBoxes) = self.parseReceipt(from: observations, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
                var result = parsedResult
                result.sourceImage = image
                result.boundingBoxes = boundingBoxes
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseReceipt(from observations: [VNRecognizedTextObservation], imageSize: CGSize) -> (OCRResult, [BoundingBox]) {
        var lines: [(text: String, observation: VNRecognizedTextObservation)] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            lines.append((topCandidate.string, observation))
        }
        
        var items: [ReceiptItem] = []
        var subtotal: Decimal?
        var vatPercentage: Decimal?
        var servicePercentage: Decimal?
        var total: Decimal?
        var boundingBoxes: [BoundingBox] = []
        
        // Simple parsing logic - in production, this would be more sophisticated
        for (line, observation) in lines {
            let lowercased = line.lowercased()
            
            // Convert normalized bounding box to image coordinates
            // Vision uses bottom-left origin, VNImageRectForNormalizedRect converts to top-left
            let normalizedRect = observation.boundingBox
            let imageRect = VNImageRectForNormalizedRect(
                normalizedRect,
                Int(imageSize.width),
                Int(imageSize.height)
            )
            
            var classification: BoundingBoxClassification = .lineItem
            
            // Look for totals
            if lowercased.contains("total") && !lowercased.contains("subtotal") {
                if let amount = extractAmount(from: line) {
                    total = amount
                    classification = .total
                }
            }
            
            if lowercased.contains("subtotal") {
                if let amount = extractAmount(from: line) {
                    subtotal = amount
                    classification = .subtotal
                }
            }
            
            if (lowercased.contains("vat") || lowercased.contains("tax")) && !lowercased.contains("subtotal") {
                if let percentage = extractPercentage(from: line) {
                    vatPercentage = percentage
                    classification = .tax
                }
            }
            
            if lowercased.contains("service") || lowercased.contains("tip") {
                if let percentage = extractPercentage(from: line) {
                    servicePercentage = percentage
                    classification = .service
                }
            }
            
            // Try to parse items (name and price pattern)
            if let item = parseItem(from: line) {
                items.append(item)
                // Only classify as lineItem if we successfully parsed it as an item
                if classification == .lineItem {
                    boundingBoxes.append(BoundingBox(
                        rectangle: imageRect,
                        text: line,
                        classification: .lineItem
                    ))
                }
            }
            
            // Add bounding box for non-line-item classifications
            if classification != .lineItem {
                boundingBoxes.append(BoundingBox(
                    rectangle: imageRect,
                    text: line,
                    classification: classification
                ))
            }
        }
        
        // If subtotal not found, calculate from items
        if subtotal == nil {
            subtotal = items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        }
        
        let result = OCRResult(
            items: items,
            subtotal: subtotal,
            vatPercentage: vatPercentage,
            servicePercentage: servicePercentage,
            total: total,
            boundingBoxes: [],
            sourceImage: nil,
            detectedRectangle: nil
        )
        
        return (result, boundingBoxes)
    }
    
    private func parseItem(from line: String) -> ReceiptItem? {
        // Pattern: "Item Name 25.50" or "Item Name x2 51.00"
        let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
        guard components.count >= 2 else { return nil }
        
        // Try to find price at the end
        var priceString: String?
        var quantity = 1
        var nameComponents: [String] = []
        
        for (index, component) in components.enumerated().reversed() {
            // Check for quantity (x2, x3, etc.)
            if component.lowercased().hasPrefix("x"), let qty = Int(component.dropFirst()) {
                quantity = qty
                continue
            }
            
            // Check if it's a price
            let cleaned = component.replacingOccurrences(of: ",", with: "")
            if let price = Decimal(string: cleaned), price > 0 {
                priceString = cleaned
                nameComponents = Array(components.prefix(index))
                break
            }
        }
        
        guard let priceStr = priceString, let unitPrice = Decimal(string: priceStr) else {
            return nil
        }
        
        let name = nameComponents.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        
        return ReceiptItem(name: name, unitPrice: unitPrice / Decimal(quantity), quantity: quantity)
    }
    
    private func extractAmount(from line: String) -> Decimal? {
        let numbers = line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let number = Decimal(string: numbers) {
            // Handle cases like "25.50" or "2550"
            if numbers.count <= 2 {
                return number / 100
            }
            // Assume last two digits are cents
            return number / 100
        }
        return nil
    }
    
    private func extractPercentage(from line: String) -> Decimal? {
        let pattern = #"(\d+(?:\.\d+)?)%"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let range = Range(match.range(at: 1), in: line),
           let percentage = Decimal(string: String(line[range])) {
            return percentage
        }
        return nil
    }
}

enum OCRError: Error {
    case invalidImage
    case processingFailed
}

