import SwiftUI

//let borderColorBufferIn = MetalObjects.device.makeBuffer(bytes: &Project.borderColor, length: MemoryLayout<SIMD3<Float>>.stride, options: .storageModeShared)

public func drawBorder() -> MTLTexture {
    let texture = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
    
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(), 
        let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
        
        let draw = MetalObjects.library.makeFunction(name:"drawBorder")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: draw)
        
        commandEncoder.setComputePipelineState(cps)
        commandEncoder.setTexture(texture, index: 0)
        
        let borderColorBufferIn = MetalObjects.device.makeBuffer(bytes: &Project.borderColor, length: MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(borderColorBufferIn, offset: 0, index: 0)
        
        let groups = MTLSize(width: texture.width/4, height: texture.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    return texture
}
