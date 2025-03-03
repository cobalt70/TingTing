//
//  ArViewModel.swift
//  TingTing
//
//  Created by Gi Woo Kim on 3/1/25.
//
import ARKit
import Combine
import SwiftUI
import RealityKit


class ARViewModel : ObservableObject{
    @Published var arView: ARView?
    @Published var raycastHitPosition: simd_float3?
    @Published var x : Float = 0
    @Published var y : Float = 0
    @Published var z : Float = 0
    @Published var tileGrid : TileGrid?
    @Published var tileGridOn: Bool = false
    @Published var isRaycasting: Bool = false
    
    @Published var isScanned: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let updateSubject = PassthroughSubject<Void, Never>()
    private var updateSubscription: Cancellable?
    init() {
        self.arView = ARView(frame: .zero)
        self.tileGrid = TileGrid()
        updateSubject
            .throttle(for: .seconds(5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.performRaycast()
                }
            .store(in: &cancellables)
//        DispatchQueue.main.async {
//            guard let arView = self.arView else {return}
//            self.updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self  ) { event in
//                print("event received \(event.self)")
//                self.performRaycast()
//                removeAnchorWithName(for: arView, name: "CenterImageAnchor")
//                loadModel(for: arView, name: "CenterImageAnchor")
//                
//            }
//        }
    }
    // ARView에서 raycast를 처리하는 메서드
    
    func requestRaycastUpdate() {
        updateSubject.send()
    }
    func performRaycast() {
        guard let arView = arView else {
            print("arView \(arView.debugDescription)")
            return }
       // 화면의 중앙에서 raycast를 수행
        let center = arView.center
        DispatchQueue.main.async{
            if let raycastQuery = arView.makeRaycastQuery(from: center, allowing: .estimatedPlane, alignment: .any) {
                
                if let raycastResult = arView.session.raycast(raycastQuery).first {
                    // 히트된 위치를 viewModel에 업데이트
                    let transform = raycastResult.worldTransform.columns.3
                    let hitPosition = simd_float3(transform.x , transform.y , transform.z)
                    DispatchQueue.main.async {
                        self.raycastHitPosition = hitPosition //  UI가 확실히 업데이트되도록 보장
                        self.x = hitPosition.x
                        self.y = hitPosition.y
                        self.z = hitPosition.z
                    }
                }
                removeAnchorWithName(for: arView, name: "CenterImageAnchor")
                loadModel(for: arView, name: "CenterImageAnchor")
            }  //
        }
    }
}
