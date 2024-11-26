import MetalKit

//var once = false

func overlayTextures(base: MTLTexture, layers: MTLTexture...) -> MTLTexture {
    //Create new base texture
    let newBase = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
    
    //Copy original base to new base
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(), let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
        let copy = MetalObjects.library.makeFunction(name: "copy")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: copy)
        
        commandEncoder.setComputePipelineState(cps)
        
        commandEncoder.setTexture(base, index: 0)
        commandEncoder.setTexture(newBase, index: 1)
        
        let groups = MTLSize(width: newBase.width/4, height: newBase.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    //Overlay
    for layer in layers {
        if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(), 
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            let overlay = MetalObjects.library.makeFunction(name:"overlay")!
            let cps = try! MetalObjects.device.makeComputePipelineState(function: overlay)
            
            commandEncoder.setComputePipelineState(cps)
            
            commandEncoder.setTexture(newBase, index: 0)
            commandEncoder.setTexture(layer, index: 1)
            
            let groups = MTLSize(width: newBase.width/4, height: newBase.height/4, depth: 1)
            let threads = MTLSize(width: 8, height: 8, depth: 1)
            
            commandEncoder.dispatchThreadgroups(groups,threadsPerThreadgroup: threads)
            commandEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
     
    return newBase
}
