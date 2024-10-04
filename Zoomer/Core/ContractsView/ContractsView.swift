import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContractsView: View {
    @State private var selectedTab = 0 // 0 for Active Jobs, 1 for Proposals
    @State private var showPostJobView = false // State to control the presentation of PostJobView
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Top bar with gradient background
                HStack {
                    Button(action: {
                        showPostJobView.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                    Text("Zoomer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        // Action for settings button
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                
                // Segmented control for switching between Active Jobs and Proposals
                Picker("View", selection: $selectedTab) {
                    Text("Active Jobs").tag(0)
                    Text("Proposals").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    ActiveJobsListView()
                } else {
                    ProposalsListView()
                }
            }
            .padding(.top, 1)
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showPostJobView) {
                PostJobView()
            }
        }
    }
}
