//
//  BankConnectionView.swift
//  Zoomer
//
//  Created by Chris on 2024-10-08.
//

import SwiftUI

struct BankConnectionView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack {
            Text("Bank Connection Setup")
                .font(.headline)
                .padding()

            // This is where you can add the logic for connecting a bank (e.g., Stripe Connect onboarding)

            Button(action: {
                // Dismiss the view after connecting the bank
                onDismiss()
            }) {
                Text("Close")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}
