import MetalKit

public func entitiesInit() -> Array<entity> {
    let device = MTLCreateSystemDefaultDevice()!
    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    
    let library = try! device.makeLibrary(source: Project.metalCode, options: nil)
    let entityInit = library.makeFunction(name:"entityInit")!
    let entityInitCPS = try! device.makeComputePipelineState(function: entityInit)
    
    commandEncoder.setComputePipelineState(entityInitCPS)
    
    let groups = MTLSize(width: Project.entityCount, height: 1, depth: 1)
    //let maxThreadsPerThreadgroup = entityInitCPS.maxTotalThreadsPerThreadgroup // 1024
    //let threadsPerThreadgroup = Project.entityCount < entityInitCPS.maxTotalThreadsPerThreadgroup ? Project.entityCount : entityInitCPS.maxTotalThreadsPerThreadgroup
    let threads = MTLSize(width: 1, height: 1, depth: 1)
    
    let entityBuffer = device.makeBuffer(length: MemoryLayout<entity>.stride * Project.entityCount, options: .storageModeShared)
    
    // Set the parameters of our gpu function
    commandEncoder.setBuffer(entityBuffer, offset: 0, index: 0)
    
    commandEncoder.dispatchThreads(groups,threadsPerThreadgroup: threads)
    
    // Tell the encoder that it is done encoding.  Now we can send this off to the gpu.
    commandEncoder.endEncoding()
    
    // Push this command to the command queue for processing
    commandBuffer.commit()
    
    // Wait until the gpu function completes before working with any of the data
    commandBuffer.waitUntilCompleted()
    
    let entityBufferPointer = entityBuffer!.contents().assumingMemoryBound(to: entity.self)
    let entityDataBufferPointer = UnsafeBufferPointer<entity>(start: entityBufferPointer, count: Project.entityCount)
    
    return Array<entity>(entityDataBufferPointer)
    //entities = Array<entity>(entityDataBufferPointer)
}

/*import MetalKit

public func entitiesInit() -> Array<entity> {
    //let device = MTLCreateSystemDefaultDevice()!
    //let commandQueue = device.makeCommandQueue()!
    let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    
    //let library = try! device.makeLibrary(source: Project.metalCode, options: nil)
    let entityInit = MetalObjects.library.makeFunction(name:"entityInit")!
    let entityInitCPS = try! MetalObjects.device.makeComputePipelineState(function: entityInit)
    
    commandEncoder.setComputePipelineState(entityInitCPS)
    
    let groups = MTLSize(width: Project.entityCount, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = entityInitCPS.maxTotalThreadsPerThreadgroup // 1024
    let threadsPerThreadgroup = Project.entityCount < entityInitCPS.maxTotalThreadsPerThreadgroup ? Project.entityCount : entityInitCPS.maxTotalThreadsPerThreadgroup
    let threads = MTLSize(width: 1, height: 1, depth: 1)
    
    let entityBuffer = MetalObjects.device.makeBuffer(length: MemoryLayout<entity>.stride * Project.entityCount, options: .storageModeShared)
    
    // Set the parameters of our gpu function
    commandEncoder.setBuffer(entityBuffer, offset: 0, index: 0)
    
    commandEncoder.dispatchThreads(groups,threadsPerThreadgroup: threads)
    
    // Tell the encoder that it is done encoding.  Now we can send this off to the gpu.
    commandEncoder.endEncoding()
    
    // Push this command to the command queue for processing
    commandBuffer.commit()
    
    // Wait until the gpu function completes before working with any of the data
    commandBuffer.waitUntilCompleted()
    
    let entityBufferPointer = entityBuffer!.contents().assumingMemoryBound(to: entity.self)
    let entityDataBufferPointer = UnsafeBufferPointer<entity>(start: entityBufferPointer, count: Project.entityCount)
    
    return Array<entity>(entityDataBufferPointer)
    //entities = Array<entity>(entityDataBufferPointer)
}
 */
