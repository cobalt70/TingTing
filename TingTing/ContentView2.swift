//
//  ContentView.swift
//  TingTing
//
//  Created by Gi Woo Kim on 2/25/25.
//
import Foundation
import SwiftUI
import RealityKit
import ARKit
import simd

struct ContentView2: View {
    @EnvironmentObject var arViewModel: ARViewModel
    var body: some View {
        ZStack{
            ARViewContainer()
                .environmentObject(arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            Image(systemName: "viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.orange) // 주황색으로 설정
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom){
            
            HStack{
                Button(action: {
                    if let arView = arViewModel.arView {
                        loadModel(for: arView)
                     
                    }
                    
                }) {
                    Text("ADD")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                }
                .frame(maxWidth: .infinity ) //
                Button(action: {
                    if let arView = arViewModel.arView {
                        var point : CGPoint = .zero
                        point.x = UIScreen.main.bounds.midX
                        point.y = UIScreen.main.bounds.midY
                        
                        findRaycastResult(for: arView, point: point)
                        
                    }
                    print("삭제")
                        
                }) {
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                }
                .frame(maxWidth: .infinity ) //
            }
        }.padding(.bottom, 0)
            .background(Color.clear)
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var arViewModel: ARViewModel
  
    var targetPoint = SIMD3<Float>(0.0, 0.0, 0.0)
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var arView : ARView?
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            print("session anchor didupdate")
        }
        
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            print("session frame didupdate")
            updateRealPointPosition(frame: frame)
            
            
        }
        
        func updateRealPointPosition(frame: ARFrame) {
            let cameraTransform = frame.camera.transform
            parent.targetPoint = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
            print("target:", parent.targetPoint)
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
        setupARView()
        context.coordinator.arView = arViewModel.arView
       
       // ARViewContainer.arView = arView
        print("\(Date()) makeUIVIew")
        return arViewModel.arView!
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let parentView = uiView.superview {
            if let arView = context.coordinator.arView {
                arView.frame = parentView.bounds
            }
        }
        print("\(Date()) updateUIView")
        
    }
    private func setupARView() {
 
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arViewModel.arView?.session.run(configuration)
     
    }
}



#Preview {
    ContentView2()
}
