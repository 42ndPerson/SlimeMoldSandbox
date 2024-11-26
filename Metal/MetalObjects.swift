import MetalKit

public class MetalObjects {
    public static let device = MTLCreateSystemDefaultDevice()!
    public static let commandQueue = device.makeCommandQueue()
    public static let library = try! device.makeLibrary(source: Project.metalCode, options: nil)
}
