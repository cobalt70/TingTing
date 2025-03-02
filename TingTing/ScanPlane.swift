//
//  LoadImage.swift
//  TingTing
//
//  Created by Gi Woo Kim on 2/28/25.
//
import RealityKit
import SwiftUI
import ARKit

func scanPlane(arViewModel :ARViewModel ) {
    guard let tileGrid = arViewModel.tileGrid else {
        return
    }
    let distance = distance(tileGrid.startPoint! ,tileGrid.endPoint!)
    let totalRows = Int((distance + (tileGrid.tileHeight)/2) / tileGrid.tileWidth ) + tileGrid.extraRows
    let totalCols = Int(Double(totalRows) * 0.1) * 2 + 1 // tile이 row == 10 > col ==3
    let centerCol = Int(totalCols / 2) // index starts friom = 0
    let tileWidth  = 0.3 // 타일의 가로 길이
    let tileHeight = 0.3 // 타일의 세로 길이
    let padding = 0.01
    let isLineCompleted = true
    let fixedY = 0.1  // 모든 타일의 y값 고정
    let startPoint = tileGrid.startPoint!
    let endPoint = tileGrid.endPoint!
//    guard let n1 = tileGrid.calculateUnitVector(from: startPoint, to: endPoint, fixedY: Float(fixedY)) else {return}
//    let n2 = tileGrid.rotate90DegreesAroundOrigin(n1)
//    
//    var n3 = simd_float3(0,1,0 ) // 사실 (0, 1, 0) 이지만 다른 용도로 사용할수도-->실제 projected plane의 법선벡터로 사용예정
//    
    tileGrid.updateGrid(totalRows: totalRows, totalCols: totalCols, centerCol: centerCol, tileWidth: Float(tileWidth), tileHeight: Float(tileHeight), padding: Float(padding), fixedY: Float(fixedY), startPoint: startPoint, endPoint: endPoint)
}


func loadModel(for arView: ARView, name : String = "") {
    // USDZ 파일 로딩
    guard let modelEntity = try? ModelEntity.loadModel(named: name == "" ? "Scene.usdz" :"scull.usdz" ) else {
        print("Failed to load the USDZ model.")
        return
    }
    
    modelEntity.generateCollisionShapes(recursive: true)
    
    // 모이 로드되면, 화면 중앙에 위치시키기 위한 raycast를 실행
    placeModelInCenter(for: arView, modelEntity: modelEntity , name : name )
    // showTracker(for: arView, modelEntity: modelEntity)
}

func removeAnchorWithName(for arView: ARView, name: String = "") {
    // name이 비어있지 않다면
    if !name.isEmpty {
        // anchors 배열을 순회하며 조건에 맞는 앵커를 제거
        for anchor in arView.scene.anchors {
            if anchor.name == name {
                arView.scene.removeAnchor(anchor) // 앵커 제거
                break // 이름이 맞는 앵커를 찾았으면 루프 종료
            }
        }
    }
}

func startSetup(arViewModel: ARViewModel) {
    // USDZ 파일 로딩
    guard let arView = arViewModel.arView  else {
        print("Failed to load arView")
        return
    }
    let center = CGPoint(x:  arView.frame.size.width / 2, y: arView.frame.size.height / 2)
    print("center \(center)")
    if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
        // Raycast 위치에서 모델을 배치
        
        arViewModel.tileGrid?.startPoint = simd_float3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y, z:result.worldTransform.columns.3.z )
        print("startPoint : \(String(describing: arViewModel.tileGrid?.startPoint))")
    }
    
}

func endSetup(arViewModel: ARViewModel) {
    
    guard let arView = arViewModel.arView  else {
        print("Failed to load arView")
        return
    }
    let center = CGPoint(x:  arView.frame.size.width / 2, y: arView.frame.size.height / 2)
    print("center \(center)")
    if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
        // Raycast 위치에서 모델을 배치
        
        arViewModel.tileGrid?.endPoint = simd_float3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y, z:result.worldTransform.columns.3.z )
       print("endPoint : \(String(describing: arViewModel.tileGrid?.endPoint))")
    }
    
}


// 화면 중앙에서 raycast하여 모델을 올려놓는 함수
func placeModelInCenter(for arView: ARView, modelEntity: ModelEntity , name : String = "" ) {
    // 화면 중앙을 기준으로 raycast 수행
    let center = CGPoint(x: arView.frame.size.width / 2, y: arView.frame.size.height / 2)
    print("center \(center)")
    if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
        // Raycast 위치에서 모델을 배치
        let anchor = AnchorEntity(world: result.worldTransform)
        print("worldTransform \(result.worldTransform.columns.3)")
        if name != "" {
            anchor.name = name
        }
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
            let entity = ModelEntity()
            entity.model = ModelComponent(mesh: planeMesh, materials: [material])
            entity.generateCollisionShapes(recursive: true)
            entity.orientation = simd_quatf(angle: -.pi / 2, axis: simd_float3(1, 0, 0))
            
            entity.name = "tracker"
            
            let center = CGPoint(x: arView.frame.size.width / 2, y: arView.frame.size.height / 2)
            print("center \(center)")
            if let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
                // Raycast 위치에서 모델을 배치
                let anchor = AnchorEntity(world: result.worldTransform)
                print("tracker \(result.worldTransform.columns.3) \(entity.name)")
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
            print(" Entity Anchor will be deleted \(anchor.debugDescription) ")
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
            .frame(width: 100, height: 100)
            .foregroundColor(.orange)
            .background(Color.clear)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
        return renderer.image { context in
            let controller = UIHostingController(rootView: image)
            controller.view.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
            controller.view.backgroundColor = .clear
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
