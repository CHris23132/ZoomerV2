import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isUserLoggedIn: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var nickname: String = ""  // New field for nickname
    @State private var errorMessage: String?  // To display errors if any

    var body: some View {
        if isUserLoggedIn {
            // Show the main tab view if the user is logged in
            TabView {
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }

                VerifyView()
                    .tabItem {
                        Image(systemName: "checkmark.seal")
                        Text("Verify")
                    }

                ContractsView()
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Contracts")
                    }

                // Pass the Binding<Bool> to AccountView
                AccountView(isUserLoggedIn: $isUserLoggedIn)
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Account")
                    }
            }
            .accentColor(.black)
        } else {
            // Show login screen if the user is not logged in
            loginView
        }
    }

    var loginView: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !isUserLoggedIn {  // Fixed condition check for nickname field
                TextField("Nickname", text: $nickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Log In") {
                login()
            }
            .padding()

            Button("Sign Up") {
                register()
            }
            .padding()
        }
        .padding()
        .onAppear {
            checkAuthStatus()
        }
    }

    // MARK: - Register New User
    func register() {
        guard !email.isEmpty, !password.isEmpty, !nickname.isEmpty else {
            self.errorMessage = "Please fill in all fields"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "Error during sign-up: \(error.localizedDescription)"
            } else if let user = authResult?.user {
                saveNickname(for: user.uid)
                self.errorMessage = nil
                self.isUserLoggedIn = true
            }
        }
    }

    // MARK: - Log In Existing User
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "Error during login: \(error.localizedDescription)"
            } else {
                self.errorMessage = nil
                self.isUserLoggedIn = true
            }
        }
    }

    // MARK: - Save Nickname to Firestore
    func saveNickname(for userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData(["nickname": nickname]) { error in
            if let error = error {
                self.errorMessage = "Error saving nickname: \(error.localizedDescription)"
            } else {
                print("Nickname saved successfully")
            }
        }
    }

    // MARK: - Check Auth Status
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            // User is logged in
            self.isUserLoggedIn = true
        } else {
            // User is not logged in
            self.isUserLoggedIn = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
