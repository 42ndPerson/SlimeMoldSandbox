import MetalKit

public func findEdges(sourceTexture: MTLTexture) -> MTLTexture {
    let edgeTexture = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
    
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(), 
        let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
        
        let draw = MetalObjects.library.makeFunction(name:"findEdgeDirections")!
        let cps = try! MetalObjects.device.makeComputePipelineState(function: draw)
        
        commandEncoder.setComputePipelineState(cps)
        
        commandEncoder.setTexture(sourceTexture, index: 0)
        commandEncoder.setTexture(edgeTexture, index: 1)
        
        let groups = MTLSize(width: sourceTexture.width/4, height: sourceTexture.height/4, depth: 1)
        let threads = MTLSize(width: 8, height: 8, depth: 1)
        
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    return edgeTexture
}
