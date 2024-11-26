public struct entity {
    public var pos: SIMD2<Float>
    public var rot: Float
    public var color: SIMD3<Float>
    
    public init (pos: SIMD2<Float>, rot: Float, color: SIMD3<Float>) {
        self.pos = pos
        self.rot = rot
        self.color = color
    }
}
