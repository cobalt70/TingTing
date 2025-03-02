//
//  ContentView.swift
//  TingTing
//
//  Created by Gi Woo Kim on 2/25/25.
//
import Combine
import Foundation
import SwiftUI
import RealityKit
import ARKit
import simd


struct ContentView2: View {
    @StateObject var arViewModel: ARViewModel = ARViewModel()
    @StateObject private var btnViewModel = ButtonViewModel()
    //    @State private var startCompleted: Bool = false
    //    @State private var endCompleted: Bool = false
    //    @State private var canScan: Bool = false
    var body: some View {
        ZStack{
            ARViewContainer()
                .environmentObject(arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            Image(systemName: "viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange) // 주황색으로 설정
                .allowsHitTesting(false)
            
            
        }
        .safeAreaInset(edge: .bottom){
            
            HStack{
                Button(action: {
                    guard let arView = arViewModel.arView else {
                        return
                    }
                    btnViewModel.startCompleted = true
                    startSetup(arViewModel: arViewModel)
                    loadModel(for: arView )
                    
                    
                }) {
                    Text("Start")
                        .font(.caption)
                        .padding()
                        .background(btnViewModel.startCompleted ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(btnViewModel.startCompleted)  // Start 버튼은 이미 시작되면 비활성화
                
                // End 버튼
                Button(action: {
                    guard let arView = arViewModel.arView else {
                        return
                    }
                    endSetup(arViewModel: arViewModel)
                    loadModel(for: arView )
                    btnViewModel.endCompleted = true
                    
                }) {
                    Text("End")
                        .font(.caption)
                        .padding()
                        .background(btnViewModel.endCompleted ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(btnViewModel.endCompleted || !btnViewModel.startCompleted)  // End 버튼은 이미 종료되면 비활성화
                
                // Scan 버튼
                Button(action: {
                    print("Scanning...")
                    // 여기에 실제 스캔 작업 로직을 넣습니다.
                    guard let arView = arViewModel.arView else {
                        return
                    }
                    scanPlane(arViewModel: arViewModel)
                    print("tileGrid \(String(describing: arViewModel.tileGrid?.tiles))")
                }) {
                    Text("Scan")
                        .font(.caption)
                        .padding()
                        .background(btnViewModel.canScan ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!btnViewModel.canScan)  // Scan 버튼은 Start와 End가 모두 완료되었을 때만 활성화
                
                // Reset 버튼
                Button(action: {
                    btnViewModel.reset()
                    guard let arView = arViewModel.arView else {
                        return
                    }
                    removeAnchorWithName(for: arView, name: "spherePlane")
                    var point : CGPoint = .zero
                    point.x = UIScreen.main.bounds.midX
                    point.y = UIScreen.main.bounds.midY
                    
                    findRaycastResult(for: arView, point: point)
                    
                    print("Reset")
                    
                    
                }) {
                    Text("Reset")
                        .font(.caption)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                } //
            }
        }.padding(.bottom, 0)
            .background(Color.clear)
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var arViewModel: ARViewModel
    static var isUpdatingScreen: Bool = false
    
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
            parent.arViewModel.requestRaycastUpdate()
           
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
        arViewModel.arView?.session.delegate = context.coordinator
        print("\(Date()) makeUIVIew")
        return arViewModel.arView!
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
//        guard !ARViewContainer.isUpdatingScreen else {return}
//        DispatchQueue.main.async {
//            ARViewContainer.isUpdatingScreen = true
//        }
        
        if let parentView = uiView.superview {
            if let arView = context.coordinator.arView {
                arView.frame = parentView.bounds
            }
        }
        
        let arView = arViewModel.arView!
        removeAnchorWithName(for: arView, name: "CenterImageAnchor")
        loadModel(for: arView, name: "CenterImageAnchor")
        
        print("\(Date()) updateUIView")
//        DispatchQueue.main.async {
//            ARViewContainer.isUpdatingScreen = false
//        }
        
    }
    
    
    private func setupARView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arViewModel.arView?.session.run(configuration)
    }
}


class ButtonViewModel: ObservableObject {
    @Published var startCompleted: Bool = false
    @Published var endCompleted: Bool = false
    
    // Combine을 사용하여 상태 변화 처리
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        // startCompleted 또는 endCompleted가 변경될 때마다 canScan 상태 업데이트
        $startCompleted
            .combineLatest($endCompleted)
            .map { start, end in
                return start && end  // 둘 다 true일 때만 true
            }
            .sink { [weak self] canScan in
                self?.canScan = canScan
            }
            .store(in: &cancellables)
    }
    
    var canScan: Bool = false  // Scan 가능 여부
    
    // Reset 버튼을 눌렀을 때 상태 초기화
    func reset() {
        startCompleted = false
        endCompleted = false
        
    }
}


#Preview {
    ContentView2()
}
