import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct VerificationItem: Identifiable {
    var id: String
    var imageUrl: String
    var description: String
    var jobId: String
    var userVote: String?
    var userComment: String = ""
}

struct VerifyView: View {
    @State private var verificationItems: [VerificationItem] = []
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if verificationItems.isEmpty {
                    Text("No verification items found.")
                        .font(.headline)
                        .padding()
                } else {
                    ZStack {
                        // Show one card at a time
                        ForEach(verificationItems.indices, id: \.self) { index in
                            if index == currentIndex {
                                VerificationCardView(item: $verificationItems[index])
                                    .offset(dragOffset)
                                    .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                                    .gesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                dragOffset = gesture.translation
                                                swipeDirection = dragOffset.width > 0 ? "approve" : "deny"
                                            }
                                            .onEnded { _ in
                                                // Animate the card off screen
                                                if dragOffset.width > 100 || dragOffset.width < -100 {
                                                    withAnimation {
                                                        dragOffset.width = dragOffset.width > 0 ? 1000 : -1000
                                                    }
                                                    submitVerification(item: verificationItems[currentIndex])
                                                    loadNextItem()
                                                } else {
                                                    dragOffset = .zero
                                                }
                                            }
                                    )
                                    .animation(.spring())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Verify")
            .navigationBarItems(
                leading: Button(action: { /* Action for post button */ }) {
                    Image(systemName: "plus.circle")
                },
                trailing: Button(action: { /* Action for settings button */ }) {
                    Image(systemName: "gearshape.fill")
                }
            )
        }
        .onAppear(perform: fetchVerificationItems)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Submission Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func fetchVerificationItems() {
        let db = Firestore.firestore()
        db.collection("verification").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching verification data: \(error.localizedDescription)")
                isLoading = false
                return
            }

            self.verificationItems = snapshot?.documents.compactMap { document -> VerificationItem? in
                let data = document.data()
                guard let imageUrl = data["imageUrl"] as? String,
                      let description = data["description"] as? String,
                      let jobId = data["jobId"] as? String else {
                    return nil
                }

                return VerificationItem(id: document.documentID, imageUrl: imageUrl, description: description, jobId: jobId)
            } ?? []

            self.isLoading = false
        }
    }
    
    private func submitVerification(item: VerificationItem) {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to vote."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        let voteData: [String: Any] = [
            "jobId": item.jobId,
            "userId": userId,
            "vote": swipeDirection == "approve" ? "approve" : "deny",
            "comment": item.userComment,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("verification_votes").addDocument(data: voteData) { error in
            if let error = error {
                print("Error saving vote: \(error.localizedDescription)")
                alertMessage = "Error saving your vote."
            } else {
                alertMessage = "Your vote has been submitted successfully!"
            }
            showAlert = true
        }
    }
    
    private func loadNextItem() {
        // Reset drag offset and load next item
        dragOffset = .zero
        if currentIndex < verificationItems.count - 1 {
            currentIndex += 1
        } else {
            // All items are reviewed
            alertMessage = "No more items to verify."
            showAlert = true
        }
    }
}

struct VerificationCardView: View {
    @Binding var item: VerificationItem

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                case .failure(_):
                    Text("Failed to load image")
                        .foregroundColor(.red)
                case .empty:
                    ProgressView()
                        .frame(height: 250)
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(item.description)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            TextField("Add a comment (max 120 chars)", text: $item.userComment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}
