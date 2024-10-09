//
//  BankingView.swift
//  Zoomer
//
//  Created by Chris on 2024-10-08.
//

import SwiftUI

struct BankingView: View {
    @State private var showPaymentSetup = false
    @State private var showBankConnection = false

    var body: some View {
        VStack {
            // Connect Payments Button
            Button(action: {
                showPaymentSetup = true
            }) {
                Text("Connect Payments")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showPaymentSetup) {
                PaymentSetupView(onDismiss: { showPaymentSetup = false })
            }

            // Connect Bank Button
            Button(action: {
                // Add action to connect bank
                showBankConnection = true
            }) {
                Text("Connect Bank")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showBankConnection) {
                BankConnectionView(onDismiss: { showBankConnection = false })
            }

            Spacer()
        }
        .navigationTitle("Banking")
        .padding()
    }
}
