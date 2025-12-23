//
//  SplashView.swift
//  FairShare
//
//  Splash screen with centered logo
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Image(systemName: "square.split.2x2")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("FairShare")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 16)
            }
        }
    }
}

