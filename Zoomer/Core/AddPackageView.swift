import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct AddPackageView: View {
    @State private var price: String = ""
    @State private var description: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false // For image picker presentation
    @State private var useCamera = false // For camera usage
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // MARK: - Header
                Text("Add New Service/Package")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .foregroundColor(.primary)
                
                // MARK: - Price Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("Enter price", text: $price)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5))
                        )
                }
                .padding(.horizontal)
                
                // MARK: - Description Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextEditor(text: $description)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5))
                        )
                        .frame(height: 120)
                }
                .padding(.horizontal)
                
                // MARK: - Image Upload Section
                VStack {
                    Button(action: {
                        isImagePickerPresented = true
                        useCamera = false
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        } else {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("Upload Image (Max 2.5MB)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                    }
                    .sheet(isPresented: $isImagePickerPresented) {
                        ImagePicker(image: $selectedImage, useCamera: $useCamera)
                    }
                }
                .padding(.horizontal)
                
                // Error message section
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                // MARK: - Submit Button
                Button(action: submitPackage) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Submit Package")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: isSubmitting ? 0 : 5)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .disabled(!isFormValid() || isSubmitting)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
        }
    }
    
    // MARK: - Submit Package
    private func submitPackage() {
        // Check if image exceeds the size limit
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.75),
              Double(imageData.count) / (1024 * 1024) <= 2.5 else {
            errorMessage = "Image exceeds 2.5MB limit."
            return
        }

        // Validate price conversion
        guard let priceDouble = Double(price) else {
            errorMessage = "Invalid price format."
            return
        }

        isSubmitting = true
        errorMessage = nil
        
        uploadImage { mediaUrl in
            guard let mediaUrl = mediaUrl else {
                errorMessage = "Failed to upload image."
                isSubmitting = false
                return
            }

            savePackageToFirestore(mediaUrl: mediaUrl, price: priceDouble)
            onDismiss() // Dismiss view after successful submission
        }
    }
    
    private func isFormValid() -> Bool {
        return !price.isEmpty && !description.isEmpty && selectedImage != nil
    }
    
    // MARK: - Upload Image to Firebase Storage
    private func uploadImage(completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("packages/\(UUID().uuidString).jpg")

        if let image = selectedImage {
            let imageData = image.jpegData(compressionQuality: 0.75)
            storageRef.putData(imageData!, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                storageRef.downloadURL { url, _ in
                    completion(url?.absoluteString)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    // MARK: - Save Package to Firestore
    private func savePackageToFirestore(mediaUrl: String, price: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let packageData: [String: Any] = [
            "price": price,
            "description": description,
            "mediaUrl": mediaUrl,
            "mediaType": "image", // Only images are supported
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userId).collection("packages").addDocument(data: packageData) { error in
            isSubmitting = false
            if let error = error {
                errorMessage = "Error saving package: \(error.localizedDescription)"
            } else {
                print("Package saved successfully")
            }
        }
    }
}
