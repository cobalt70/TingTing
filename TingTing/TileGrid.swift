//
//  TileGrid.swift
//  TingTing
//
//  Created by Gi Woo Kim on 3/1/25.
//

import simd
import SwiftUI


/// 개별 타일을 나타내는 구조체
struct Tile {
    
    var topLeft: simd_float3 = .zero
    var topRight: simd_float3  = .zero
    var bottomRight: simd_float3 = .zero
    var bottomLeft: simd_float3 = .zero
    
    var center: simd_float3 = .zero
    var normalVector: simd_float3 = .zero
    
    var row: Int
    var col: Int
    
    var projected: Bool = false
    
    init (row: Int, col: Int, topLeft: simd_float3 , topRight :simd_float3 , bottomRight : simd_float3,
          bottomLeft: simd_float3, center: simd_float3, normal: simd_float3 , projected : Bool = false) {
        self.row = row
        self.col = col
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.center = center
        self.normalVector = normal
        self.projected = projected
        
    }
    
    init (row: Int, col: Int, position: [simd_float3?] , normal : simd_float3, projected : Bool = false) {
        
        self.row = row
        self.col = col
        if let topLeft = position[0] {
            self.topLeft = topLeft
        }
        if let topRight = position[1] {
            self.topRight = topRight
        }
        
        if let bottomRight = position[2] {
            self.bottomRight = bottomRight
        }
        if let bottomLeft = position[3] {
            self.bottomLeft = bottomLeft
        }
        if let center = position[4] {
            self.center = center
        }
        
        if let center = position[4] {
            self.center = center
        }
        self.normalVector = normal
        self.projected = projected
    }
}
    /// 타일 그리드를 관리하는 class
    
    @Observable
    class TileGrid  {
        var totalRows: Int?
        var totalCols: Int?
        var centerCol : Int?
        
        var tileWidth: Float  = 0.3 // 타일의 가로 길이
        var tileHeight: Float = 0.3 // 타일의 세로 길이
        var padding: Float    = 0.02// 타일 간 간격
        var extraRows: Int = 1
        
        var startPoint: simd_float3?
        var endPoint: simd_float3?
        
        var isLineCompleted: Bool = false
        
        var fixedY: Float = 0// 모든 타일의 y값 고정
        
        var n1 : simd_float3?
        var n2 : simd_float3?
        var n3 : simd_float3? // 사실 (0, 1, 0) 이지만 다른 용도로 사용할수도-->실제 projected plane의 법선벡터로 사용예정
        
        
        var tiles: [[Tile?]] = []
        var projectedTiles : [[Tile?]] = [[]]
        
        init() {
            
            
        }
        init(totalRows: Int, totalCols: Int,centerCol : Int,  tileWidth: Float, tileHeight: Float, padding: Float, fixedY: Float, startPoint: simd_float3, endPoint: simd_float3) {
            self.totalRows = totalRows
            self.totalCols = totalCols
            self.centerCol = centerCol
            
            self.tileWidth = tileWidth
            self.tileHeight = tileHeight
            self.padding = padding
            self.startPoint = startPoint
            self.endPoint = endPoint
            self.fixedY = max(startPoint.y , endPoint.y ) + 0.3
            
            self.startPoint?.y = self.fixedY
            self.endPoint?.y = self.fixedY
            
            if let n1 = calculateUnitVector(from: startPoint, to: endPoint , fixedY: fixedY) {
                self.n1 = n1
                self.n2 = rotate90DegreesAroundOrigin(n1)
                self.n3 = simd_float3(0, 1, 0)
            }
            self.projectedTiles = Array(repeating: Array(repeating: nil, count: totalRows), count: totalCols)
            self.projectedTiles = Array(repeating: Array(repeating: nil, count: totalRows), count: totalCols)
            
            self.tiles = generateTiles()
        }
        func updateGrid(totalRows: Int, totalCols: Int, centerCol: Int, tileWidth: Float, tileHeight: Float, padding: Float, fixedY: Float, startPoint: simd_float3, endPoint: simd_float3) {
            self.totalRows = totalRows
            self.totalCols = totalCols
            self.centerCol = centerCol
            
            self.tileWidth = tileWidth
            self.tileHeight = tileHeight
            self.padding = padding
            self.startPoint = startPoint
            self.endPoint = endPoint
            self.fixedY = fixedY
            
            self.startPoint?.y = fixedY
            self.endPoint?.y = fixedY
            self.isLineCompleted = true
            self.tiles = [[]]
            if let n1 = calculateUnitVector(from: startPoint, to: endPoint, fixedY: fixedY) {
                self.n1 = n1
                self.n2 = rotate90DegreesAroundOrigin(n1)
                self.n3 = simd_float3(0, 1, 0)
            }
            
            self.tiles = generateTiles()
            
        }
        
        // 두 점을 입력받아 Y 값을 고정하고, 단위 벡터를 계산하는 함수
        func calculateUnitVector(from startPoint: simd_float3, to endPoint: simd_float3, fixedY: Float) -> simd_float3? {
            // Y값 고정하고, X, Z 평면에서만 벡터 차이 계산
            let direction = simd_float3(endPoint.x - startPoint.x, fixedY - fixedY, endPoint.z - startPoint.z)
            
            // 벡터의 크기 계산 (X, Z만 고려)
            let lengthXZ = sqrt(direction.x * direction.x + direction.z * direction.z)
            
            // 벡터의 길이가 0이면 (두 점이 동일한 위치에 있을 경우), 단위 벡터를 계산할 수 없으므로 nil 반환
            if lengthXZ == 0 {
                return nil
            }
            
            // 단위 벡터로 정규화
            let unitVector = direction / lengthXZ
            
            return unitVector
        }
        
        private func normalize(_ vector: simd_float3) -> simd_float3 {
            let length = simd_length(vector)
            return length > 0 ? vector / length : simd_float3(0, 0, 0)
        }
        
        /// 90도 반시계 방향 회전 (X-Z 평면 기준)
        func rotate90DegreesAroundOrigin( _ vector: simd_float3) -> simd_float3 {
            let rotationMatrix = simd_float3x3(
                simd_float3(0,  0, -1), // X' = -Z
                simd_float3(0,  1,  0), // Y' = Y (변화 없음)
                simd_float3(1,  0,  0)  // Z' = X
            )
            return rotationMatrix * vector
        }
        
        /// 타일 생성 로직
        private func generateTiles() -> [[Tile?]] {
            var generatedTiles: [[Tile?]] = []
            
            // 방향 벡터 및 단위 벡터 계산
            guard let endPoint = self.endPoint, let startPoint = self.startPoint else {
                return []
            }
            let directionVector = endPoint - startPoint
            let forwardUnitVector = normalize(directionVector) // 주 방향 벡터 (start → end)
            let sideUnitVector = rotate90DegreesAroundOrigin(forwardUnitVector) // 90도 회전 벡터
            guard let totalCols = self.totalCols, let totalRows = self.totalRows, let centerCol = self.centerCol else {
                return []
            }
            for col in 0..<totalCols {
                var tileCol: [Tile] = []
                
                for row in 0..<totalRows {
                    // 타일 중심 좌표 계산
                    // 중심 centerCol을 가지고있어야 몇번째 column이 공과 홀컵간의 중심이 되는 컬럼인지 판별가능
                    
                    let center = startPoint + forwardUnitVector * Float(row) * (tileHeight + padding) + sideUnitVector * Float(col - centerCol) * (tileWidth + padding)
                    // 사각형의 4개 꼭짓점 계산
                    let halfWidth = tileWidth / 2.0
                    let halfHeight = tileHeight / 2.0
                    
                    // n1: forwardUnitVector, n2: sideUnitVector
                    let n1 = forwardUnitVector  // 세로 방향 (forward)
                    let n2 = sideUnitVector    // 가로 방향 (side)
                    
                    // 각 꼭짓점 계산 (벡터 연산으로 개선)
                    let topLeft = center - n2 * halfWidth + n1 * halfHeight
                    let topRight = center + n2 * halfWidth + n1 * halfHeight
                    let bottomLeft = center - n2 * halfWidth - n1 * halfHeight
                    let bottomRight = center + n2 * halfWidth - n1 * halfHeight
                    // 노멀 벡터 (기본적으로 위쪽을 가리킴)
                    let normalVector = simd_float3(0, 1, 0)
                    
                    // 타일 생성
                    let tile = Tile( row: row, col: col,
                                     topLeft: topLeft, topRight: topRight,
                                     bottomRight: bottomRight, bottomLeft: bottomLeft,
                                     center: center, normal: normalVector)
                    tileCol.append(tile)
                }
                generatedTiles.append(tileCol)
            }
            
            return generatedTiles
        }
        
        /// 특정 위치의 타일을 가져오는 함수 (안전한 접근)
        func getTile(atRow row: Int, col: Int) -> Tile? {
            guard let totalCols = self.totalCols, let totalRows = self.totalRows else {
                return nil
            }
            guard row >= 0, row < totalRows, col >= 0, col < totalCols else {
                return nil // 범위를 벗어나면 nil 반환
            }
            return tiles[col][row]
        }
    }
    

