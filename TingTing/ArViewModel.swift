//
//  ArViewModel.swift
//  TingTing
//
//  Created by Gi Woo Kim on 3/1/25.
//
import SwiftUI
import RealityKit

@Observable
class ARViewModel: ObservableObject {
    var arView: ARView?
    var tileGrid : TileGrid?
    var tileGridOn: Bool = false
    init() {
        self.arView = ARView(frame: .zero)
    }
}
