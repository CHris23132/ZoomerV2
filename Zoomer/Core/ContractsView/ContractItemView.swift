//
//  ContractItemView.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-31.
//

import SwiftUI

struct ContractItemView: View {
    var status: String
    var name: String
    var rating: Double
    var description: String
    var onComplete: () -> Void // Callback for "Finish" button

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(status)
                        .font(.headline)
                        .foregroundColor(status == "In Progress" ? .orange : (status == "Completed" ? .green : .blue))
                    Text(name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                    }
                    .padding(.bottom, 2)
                    Text("See details")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)

            if status == "In Progress" {
                Button(action: onComplete) {
                    Text("Finish")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
