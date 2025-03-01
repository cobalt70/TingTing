//
//  LoadImage.swift
//  TingTing
//
//  Created by Gi Woo Kim on 2/28/25.
//
import RealityKit
import SwiftUI
import ARKit
func loadModel(for arView: ARView) {
    // USDZ 파일 로딩
    guard let modelEntity = try? ModelEntity.loadModel(named: "Scene.usdz") else {
        print("Failed to load the USDZ model.")
        return
    }
    modelEntity.generateCollisionShapes(recursive: true)

    // 모이 로드되면, 화면 중앙에 위치시키기 위한 raycast를 실행
   // placeModelInCenter(for: arView, modelEntity: modelEntity)
    showTracker(for: arView, modelEntity: modelEntity)
}

// 화면 중앙에서 raycast하여 모델을 올려놓는 함수
func placeModelInCenter(for arView: ARView, modelEntity: ModelEntity) {
    // 화면 중앙을 기준으로 raycast 수행
    let center = CGPoint(x: arView.frame.size.width / 2, y: arView.frame.size.height / 2)
    print("center \(center)")
    if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
        // Raycast 위치에서 모델을 배치
        let anchor = AnchorEntity(world: result.worldTransform)
        print("worldTransform \(result.worldTransform.columns.3)")
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
    }
}

func showTracker(for arView: ARView, modelEntity: ModelEntity){
    if let uiImage = convertSwiftUIImageToUIImage(systemName: "viewfinder"),
       let cgImage = uiImage.cgImage {

        // Create the texture resource using the new initializer (with init(image:withName:options:))
        let textureResource = try? TextureResource(image: cgImage, withName: "viewfinderTexture", options: .init(semantic: .color))

        // Check if the texture resource is successfully created
        if let textureResource = textureResource {
            
            // Create the material and apply the texture correctly using MaterialParameters
            var material = UnlitMaterial(texture: textureResource)
            material.color.tint = UIColor.yellow
            // Create the plane mesh with the desired size
            let planeMesh = MeshResource.generatePlane(width: 0.2, height: 0.2) // 20cm 크기
            
            // Create the model entity with the mesh and material
            let entity = ModelEntity()
            entity.model = ModelComponent(mesh: planeMesh, materials: [material])
            
            // Position the entity 1 meter in front of the camera
            
            let center = CGPoint(x: arView.frame.size.width / 2, y: arView.frame.size.height / 2)
            print("center \(center)")
            if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
                // Raycast 위치에서 모델을 배치
                let anchor = AnchorEntity(world: result.worldTransform)
                print("tracker \(result.worldTransform.columns.3)")
                anchor.addChild(entity)
                arView.scene.addAnchor(anchor)
            }
            
        }
    }
    
}

func findRaycastResult(for arView: ARView, point: CGPoint) {
    
    print("point : \(point)")
    if let entity = arView.entity(at: point) {
        print(" Entity name : \(entity.name)")
        if let anchor = entity.anchor {
            print(" Entity Anchor will be deleted \(anchor) ")
            arView.scene.removeAnchor(anchor)
        } else {
            print("this entity doesn't have an anchor.")
        }
        
        
    } else {
        print("no entity hitting the real surface")
        let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
        if let firstResult = results.first {
            let position = simd_make_float3(firstResult.worldTransform.columns.3)
            print("location \(position)")
        } else {
            print("no entity  no surface")
        }
    }
}

private func convertSwiftUIImageToUIImage(systemName: String) -> UIImage? {
        let image = Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundColor(.orange)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
        return renderer.image { context in
            let controller = UIHostingController(rootView: image)
            controller.view.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
            controller.view.backgroundColor = .clear
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
