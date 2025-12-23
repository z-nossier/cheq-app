//
//  HomeView.swift
//  FairShare
//
//  Home screen with greeting and recent receipts
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showScan = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(authViewModel.currentUser?.firstName ?? "there")")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Split your bills fair & square")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Scan button
                    Button(action: {
                        showScan = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan New Receipt")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .frame(minHeight: Constants.minimumTapTargetSize)
                    .accessibilityLabel("Scan New Receipt")
                    .accessibilityHint("Opens camera to scan a receipt")
                    
                    // Recent receipts
                    if !viewModel.recentReceipts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Receipts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.recentReceipts) { receipt in
                                ReceiptRowView(receipt: receipt)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("FairShare")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScan) {
                ScanView()
            }
            .onAppear {
                viewModel.refreshReceipts()
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt
    @State private var currency = StorageService.shared.loadCurrency()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.items.count == 1 ? "1 item" : "\(receipt.items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(receipt.total.formatted(currency: currency))
                    .font(.headline)
            }
            
            Spacer()
            
            Text(receipt.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

