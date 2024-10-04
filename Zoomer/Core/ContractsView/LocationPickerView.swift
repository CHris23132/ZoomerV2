//
//  LocationPickerView.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-18.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedAddress: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var searchQuery = ""
    @State private var mapItems = [IdentifiableMapItem]() // Use the wrapper instead of MKMapItem
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a place", text: $searchQuery, onCommit: {
                    searchLocations()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                Map(coordinateRegion: $region, annotationItems: mapItems) { item in
                    MapPin(coordinate: item.mapItem.placemark.coordinate)
                }
                .edgesIgnoringSafeArea(.bottom)

                Button(action: {
                    if let firstItem = mapItems.first?.mapItem {
                        self.selectedAddress = firstItem.placemark.title ?? ""
                        self.selectedCoordinate = firstItem.placemark.coordinate
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Confirm Location")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(mapItems.isEmpty)
            }
            .navigationBarTitle("Pick a Location", displayMode: .inline)
        }
    }

    private func searchLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                self.mapItems = response.mapItems.map { IdentifiableMapItem(mapItem: $0) }
                if let firstItem = response.mapItems.first {
                    self.region = MKCoordinateRegion(
                        center: firstItem.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
}
