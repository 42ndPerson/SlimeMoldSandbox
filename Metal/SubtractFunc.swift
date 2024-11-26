import MetalKit

public func subtract(storageTexture: inout MTLTexture) {
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(), 
        let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
        
        let subtract = MetalObjects.library.makeFunction(name:"subtract")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: subtract)
        
        commandEncoder.setComputePipelineState(cps)
        
        commandEncoder.setTexture(storageTexture, index: 0)
        
        let subtractValueBufferIn = MetalObjects.device.makeBuffer(bytes: &Project.simulationSettings.subtractValue, length: MemoryLayout<Float>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(subtractValueBufferIn, offset: 0, index: 0)
        
        let groups = MTLSize(width: storageTexture.width/4, height: storageTexture.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups,threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
