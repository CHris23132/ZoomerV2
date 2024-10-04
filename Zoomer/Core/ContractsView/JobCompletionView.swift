import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct JobCompletionView: View {
    var job: JobListing
    @Environment(\.presentationMode) var presentationMode
    @State private var description: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var useCamera: Bool = true // Use the camera by default

    var body: some View {
        NavigationView {
            VStack {
                TextField("Describe the job completion...", text: $description)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                Button(action: { showImagePicker.toggle() }) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(8)
                    } else {
                        Text("Take Photo")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage, useCamera: $useCamera)
                }
                
                Button(action: submitJobCompletion) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(description.isEmpty || selectedImage == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(description.isEmpty || selectedImage == nil)
            }
            .padding()
            .navigationTitle("Complete Job")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func submitJobCompletion() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }

        isSubmitting = true

        // Ensure image data is available and compress it
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.5) else {
            print("Error: Could not compress image.")
            isSubmitting = false
            return
        }

        print("Image data size: \(imageData.count) bytes")

        let storageRef = Storage.storage().reference().child("verification_images/\(UUID().uuidString).jpg")

        // Upload the image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                isSubmitting = false
                return
            }

            // Retrieve the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting image URL: \(error.localizedDescription)")
                    isSubmitting = false
                    return
                }

                guard let imageUrl = url?.absoluteString else {
                    print("Error: Image URL is nil.")
                    isSubmitting = false
                    return
                }

                print("Image uploaded successfully. URL: \(imageUrl)")

                // Save the job completion data to Firestore
                let db = Firestore.firestore()
                let verificationData: [String: Any] = [
                    "jobId": self.job.id!,
                    "description": self.description,
                    "imageUrl": imageUrl,
                    "timestamp": Timestamp(date: Date()),
                    "status": "Pending",
                    "userId": userId
                ]

                db.collection("verification").addDocument(data: verificationData) { error in
                    if let error = error {
                        print("Error saving verification data: \(error.localizedDescription)")
                        isSubmitting = false
                        return
                    }

                    print("Verification data saved. Updating job status...")

                    // Mark job as pending and start listening for votes
                    db.collection("job_listings").document(self.job.id!).updateData(["status": "Pending"]) { error in
                        if let error = error {
                            print("Error updating job status: \(error.localizedDescription)")
                        } else {
                            print("Job status updated successfully.")
                        }
                        isSubmitting = false
                        self.presentationMode.wrappedValue.dismiss()

                        // Start listening for votes after the job is marked as Pending
                        VoteManager.listenForJobVotes(jobId: self.job.id!)
                    }
                }
            }
        }
    }
}
