import MetalPerformanceShaders

public func blurImage(texture: inout MTLTexture) {
    if let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer() {
        let blur = MPSImageGaussianBlur(device: MetalObjects.device, sigma: Project.simulationSettings.blurSigma)
        blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture)
        //blur.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: texture)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
