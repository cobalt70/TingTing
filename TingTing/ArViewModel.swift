//
//  ArViewModel.swift
//  TingTing
//
//  Created by Gi Woo Kim on 3/1/25.
//
import SwiftUI
import RealityKit

class ARViewModel: ObservableObject {
    @Published var arView: ARView?

    init() {
        self.arView = ARView(frame: .zero)
    }
}
