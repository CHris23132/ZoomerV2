//
//  IdentifiableMapItem.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-18.
//

import SwiftUI
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()  // A unique identifier for each map item
    let mapItem: MKMapItem
}
