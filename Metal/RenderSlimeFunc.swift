import MetalKit
import MetalPerformanceShaders

public func renderSlime(texture: inout MTLTexture, edges: MTLTexture) {
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer() {
        let blur = MPSImageGaussianBlur(device: MetalObjects.device, sigma: Project.simulationSettings.blurSigma)
        blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    subtract(storageTexture: &texture)
    
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(),
       let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
        
        let update = MetalObjects.library.makeFunction(name:"slimeViewer")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: update)
        
        commandEncoder.setComputePipelineState(cps)
        
        let entityBuffer = MetalObjects.device.makeBuffer(bytes: &Project.entities, length: MemoryLayout<entity>.stride * Project.entityCount, options: .storageModeShared)
        commandEncoder.setBuffer(entityBuffer, offset: 0, index: 0)
        let settingsBuffer = MetalObjects.device.makeBuffer(bytes: &Project.simulationSettings, length: MemoryLayout<Project.SimulationSettings>.stride, options: .storageModeShared)
        commandEncoder.setBuffer(settingsBuffer, offset: 0, index: 1)
        
        commandEncoder.setTexture(texture, index: 0)
        commandEncoder.setTexture(edges, index: 1)
        
        let groups = MTLSize(width: Project.entityCount/1000, height: 1, depth: 1)
        let threads = MTLSize(width: 1000, height: 1, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups,threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let entityBufferPointer = entityBuffer!.contents().assumingMemoryBound(to: entity.self)
        let entityDataBufferPointer = UnsafeBufferPointer<entity>(start: entityBufferPointer, count: Project.entityCount)
        Project.entities = Array<entity>(entityDataBufferPointer)
    }
}
