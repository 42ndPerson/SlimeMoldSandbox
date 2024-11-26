import MetalPerformanceShaders

public func scaleImage(newSize: CGSize, texture: MTLTexture) -> MTLTexture {
    let outputTexture = makeTexture(width: Int(newSize.width), height: Int(newSize.height))

    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer() {
        let scale = MPSImageLanczosScale(device: MetalObjects.device)
        var transform = MPSScaleTransform(scaleX: newSize.width/CGFloat(texture.width), scaleY: newSize.height/CGFloat(texture.height), translateX: 0, translateY: 0)
        
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            scale.scaleTransform = transformPtr
            //scale.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture)
            scale.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: outputTexture)
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    return outputTexture
}
