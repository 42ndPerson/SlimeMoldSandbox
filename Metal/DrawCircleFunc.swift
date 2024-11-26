import MetalKit

let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer()

public class Shapes {
    let commandBuffer: MTLCommandBuffer
    let commandEncoder: MTLComputeCommandEncoder
    
    public init() {
        self.commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer()!
        self.commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    }
        
    public func drawCircle(pos: SIMD2<UInt32>, radius: UInt32, color: inout SIMD4<Float>, texture: inout MTLTexture) {
        var posVal = pos
        var radiusVal = radius
        
        let draw = MetalObjects.library.makeFunction(name:"drawCircle")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: draw)
        
        commandEncoder.setComputePipelineState(cps)
        
        let circlePosBufferIn = MetalObjects.device.makeBuffer(bytes: &posVal, length: MemoryLayout<SIMD2<UInt32>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(circlePosBufferIn, offset: 0, index: 0)
        let circleRadiusBufferIn = MetalObjects.device.makeBuffer(bytes: &radiusVal, length: MemoryLayout<UInt32>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(circleRadiusBufferIn, offset: 0, index: 1)
        let borderColorBufferIn = MetalObjects.device.makeBuffer(bytes: &color, length: MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(borderColorBufferIn, offset: 0, index: 2)
        
        commandEncoder.setTexture(texture, index: 0)
        
        let groups = MTLSize(width: texture.width/4, height: texture.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    public func drawRect(end1: SIMD2<UInt32>, end2: SIMD2<UInt32>, radius: UInt32, color: inout SIMD4<Float>, texture: inout MTLTexture) {
        var end1Val = end1
        var end2Val = end2
        var radiusVal = radius
        
        let draw = MetalObjects.library.makeFunction(name:"drawRect")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: draw)
        
        commandEncoder.setComputePipelineState(cps)
        
        let end1PosBufferIn = MetalObjects.device.makeBuffer(bytes: &end1Val, length: MemoryLayout<SIMD2<UInt32>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(end1PosBufferIn, offset: 0, index: 0)
        let end2PosBufferIn = MetalObjects.device.makeBuffer(bytes: &end2Val, length: MemoryLayout<SIMD2<UInt32>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(end2PosBufferIn, offset: 0, index: 1)
        let radiusBufferIn = MetalObjects.device.makeBuffer(bytes: &radiusVal, length: MemoryLayout<UInt32>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(radiusBufferIn, offset: 0, index: 2)
        let borderColorBufferIn = MetalObjects.device.makeBuffer(bytes: &color, length: MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(borderColorBufferIn, offset: 0, index: 3)
        
        commandEncoder.setTexture(texture, index: 0)
        
        let groups = MTLSize(width: texture.width/4, height: texture.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
