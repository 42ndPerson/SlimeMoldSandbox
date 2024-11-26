import SwiftUI

func scale2dPoint(point: SIMD2<UInt32>, oldSize: CGSize, newSize: CGSize) -> SIMD2<UInt32> {
    return SIMD2<UInt32>(UInt32(Float(point.x)*Float(oldSize.width/newSize.width)), UInt32(Float(point.y)*Float(oldSize.height/newSize.height)))
}
