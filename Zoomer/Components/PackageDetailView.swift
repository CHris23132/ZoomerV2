//
//  PackageDetailView.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-09-07.
//

import SwiftUI

struct PackageDetailView: View {
    var package: Package
    
    var body: some View {
        VStack(spacing: 20) {
            // Display the package image
            if let imageUrl = URL(string: package.mediaUrl) {
                AsyncImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(10)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                Text("No Image Available")
            }
            
            // Display package price
            Text("Price: $\(String(format: "%.2f", package.price))")
                .font(.title2)
                .fontWeight(.bold)
            
            // Display package description
            Text(package.description)
                .font(.body)
                .padding()
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Package Details")
    }
}
