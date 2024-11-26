import MetalKit

public func makeTexture(width: Int, height: Int) -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
    return MetalObjects.device.makeTexture(descriptor: textureDescriptor)!
}
