import SwiftUI
import Firebase
import FirebaseCore
import Stripe  // Import Stripe SDK

// AppDelegate for Firebase and Stripe configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // Initialize Firebase
        
        // Retrieve Stripe publishable key from Info.plist
        if let stripePublishableKey = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String {
            StripeAPI.defaultPublishableKey = stripePublishableKey
        } else {
            print("Stripe publishable key not found.")
        }

        return true
    }

    // Handle Stripe URL callbacks (for 3D Secure or Stripe Connect onboarding)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return StripeAPI.handleURLCallback(with: url)
    }
}

@main
struct ZoomerApp: App {
    
    // Register the AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // FirebaseAuth and Firestore DataManager
    @StateObject var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager) // Provide DataManager to ContentView
        }
    }
}

// DataManager to handle Firestore operations
class DataManager: ObservableObject {
    @Published var dogs: [Dog] = []

    func fetchDogs() {
        let db = Firestore.firestore()
        db.collection("dogs").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching dogs: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot {
                self.dogs = snapshot.documents.map { doc in
                    let data = doc.data()
                    let id = data["id"] as? String ?? UUID().uuidString
                    let breed = data["breed"] as? String ?? ""
                    return Dog(id: id, breed: breed)
                }
            }
        }
    }

    func addDog(breed: String) {
        let db = Firestore.firestore()
        let newDog = ["id": UUID().uuidString, "breed": breed]
        db.collection("dogs").addDocument(data: newDog) { error in
            if let error = error {
                print("Error adding dog: \(error.localizedDescription)")
            }
        }
    }
}

// Dog model conforming to Identifiable protocol
struct Dog: Identifiable {
    var id: String
    var breed: String
}
