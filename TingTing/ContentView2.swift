//
//  ContentView.swift
//  TingTing
//
//  Created by Gi Woo Kim on 2/25/25.
//

import SwiftUI
import RealityKit
import ARKit
import simd

struct ContentView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @StateObject private var targetPoint = RealPoint(position: SIMD3<Float>(0.0, 0.0, 0.0))
  
    @State private var arView :   ARView?

    class Coordinator: NSObject, ARSessionDelegate {
        
        var parent: ARViewContainer
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            print("session anchor didupdate")
        }
     
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 실시간으로 카메라 위치 업데이트
            print("session frame didupdate")
            updateRealPointPosition(frame: frame)
        }
        
        // 카메라 위치 업데이트
        
        func updateRealPointPosition(frame: ARFrame) {
            
            let arview = parent.arView
            let cameraTransform = frame.camera.transform
            parent.targetPoint.position = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
           
            print("target :", parent.targetPoint.position ?? SIMD3<Float> (-1,-1,-1))
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("Session interruption ended")
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .notAvailable:
                print("Tracking not available")
            case .limited(let reason):
                print("Tracking limited: \(reason)")
            case .normal:
                print("Tracking normal")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        DispatchQueue.main.async {
            self.arView = arView
            let configuration = ARWorldTrackingConfiguration()
                    configuration.planeDetection = [.horizontal, .vertical]
            arView.session.delegate = context.coordinator
            print("\(Date()) makeUIVIew")
        }
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("\(Date()) updateUIView")
    }
}



#Preview {
    ContentView()
}
