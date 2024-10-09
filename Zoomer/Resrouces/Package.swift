// Package.swift
// Zoomer
//
// Created by Chris on 2024-10-08.

import Foundation

// Define the Package struct
struct Package: Identifiable {
    var id: String
    var price: Double
    var description: String
    var mediaUrl: String
    var mediaType: String // Example: "image"
}
