//
//  User.swift
//  FairShare
//
//  User profile model
//

import Foundation

struct User: Codable {
    let id: String
    let name: String
    let email: String
    var currency: Currency
    
    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}

enum Currency: String, Codable, CaseIterable {
    case egp = "EGP"
    case aed = "AED"
    case sar = "SAR"
    case usd = "USD"
    case eur = "EUR"
    
    var symbol: String {
        switch self {
        case .egp: return "E£"
        case .aed: return "د.إ"
        case .sar: return "﷼"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

