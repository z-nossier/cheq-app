//
//  SummaryView.swift
//  FairShare
//
//  Summary screen with per-person breakdown
//

import SwiftUI

struct SummaryView: View {
    @State var receipt: Receipt
    @StateObject private var viewModel: SummaryViewModel
    @State private var showShareSheet = false
    @State private var currency = StorageService.shared.loadCurrency()
    @Environment(\.dismiss) var dismiss
    
    init(receipt: Receipt) {
        self._receipt = State(initialValue: receipt)
        _viewModel = StateObject(wrappedValue: SummaryViewModel(receipt: receipt))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary header
                    Text("Bill Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Per-person breakdown
                    ForEach(viewModel.splits, id: \.person.id) { split in
                        PersonSummaryCard(split: split, currency: currency)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    // Total verification
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(receipt.total.formatted(currency: currency))
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [viewModel.generateShareText(currency: currency)])
            }
        }
    }
}

struct PersonSummaryCard: View {
    let split: PersonSplit
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                    Text(split.person.name)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Items")
                    Spacer()
                    Text(split.itemTotal.formatted(currency: currency))
                }
                
                if split.vatShare > 0 {
                    HStack {
                        Text("VAT")
                        Spacer()
                        Text(split.vatShare.formatted(currency: currency))
                    }
                }
                
                if split.serviceShare > 0 {
                    HStack {
                        Text("Service")
                        Spacer()
                        Text(split.serviceShare.formatted(currency: currency))
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(split.finalAmount.formatted(currency: currency))
                        .font(.headline)
                        .contentTransition(.numericText())
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(split.person.name) owes \(split.finalAmount.formatted(currency: currency))")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

