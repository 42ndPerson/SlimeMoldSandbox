import MetalKit
import MetalPerformanceShaders

public class SandboxDelegate: NSObject, MTKViewDelegate {
    weak var view: MTKView!
    
    private var baseTrailsTexture: MTLTexture!
    private var borderTexture: MTLTexture!
    private var wallsTexture: MTLTexture!
    private var edgesTexture: MTLTexture!
    private var compTexture: MTLTexture!
    
    private var drawableSize: CGSize = Project.viewFrame
    
    public init?(mtkView: MTKView) {
        self.view = mtkView
        self.view.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
        self.view.colorPixelFormat = .bgra8Unorm
        
        self.baseTrailsTexture = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
        self.wallsTexture = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
        self.compTexture = makeTexture(width: Int(Project.viewFrame.width), height: Int(Project.viewFrame.height))
        
        self.borderTexture = drawBorder()
        
        self.edgesTexture = findEdges(sourceTexture: self.borderTexture)
        
        super.init()
        self.view.delegate = self
        self.view.framebufferOnly = false
        self.view.device = MetalObjects.device
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    public func draw(in view: MTKView) {
        if(!UserControl.instance.simPaused) {
            renderSlime(texture: &self.baseTrailsTexture, edges: self.edgesTexture)
        }
        
        var point1: SIMD2<UInt32>? = nil
        var point2: SIMD2<UInt32>? = nil
        for (i, point) in UserControl.instance.wallKeyPoints.enumerated() {
            point2 = SIMD2<UInt32>(2*UInt32(max(point.x,0)), 2*UInt32(max(point.y,0)))
            
            if(point1 != nil) {
                if(!UserControl.instance.isErasing) {
                    Shapes().drawCircle(pos: scale2dPoint(point: point1!, oldSize: Project.viewFrame, newSize: drawableSize), radius: UInt32(20), color: &Project.borderColor, texture: &self.wallsTexture)
                    Shapes().drawRect(
                        end1: scale2dPoint(point: point1!, oldSize: Project.viewFrame, newSize: drawableSize), 
                        end2: scale2dPoint(point: point2!, oldSize: Project.viewFrame, newSize: drawableSize), 
                        radius: UInt32(20), 
                        color: &Project.borderColor,
                        texture: &self.wallsTexture
                    )
                    
                    if(i==UserControl.instance.wallKeyPoints.count-1) {
                        Shapes().drawCircle(pos: scale2dPoint(point: SIMD2<UInt32>(point2!.x, point2!.y), oldSize: Project.viewFrame, newSize: drawableSize), radius: UInt32(20), color: &Project.borderColor, texture: &self.wallsTexture)
                    }
                } else {
                    Shapes().drawCircle(pos: scale2dPoint(point: point1!, oldSize: Project.viewFrame, newSize: drawableSize), radius: UInt32(40), color: &Project.backgroundColor, texture: &self.wallsTexture)
                    Shapes().drawRect(
                        end1: scale2dPoint(point: point1!, oldSize: Project.viewFrame, newSize: drawableSize), 
                        end2: scale2dPoint(point: point2!, oldSize: Project.viewFrame, newSize: drawableSize), 
                        radius: UInt32(40), 
                        color: &Project.backgroundColor,
                        texture: &self.wallsTexture
                    )
                    
                    if(i==UserControl.instance.wallKeyPoints.count-1) {
                        Shapes().drawCircle(pos: scale2dPoint(point: SIMD2<UInt32>(point2!.x, point2!.y), oldSize: Project.viewFrame, newSize: drawableSize), radius: UInt32(20), color: &Project.backgroundColor, texture: &self.wallsTexture)
                    }
                }
            }
            
            point1 = point2
        }
        if(UserControl.instance.simPaused && !UserControl.instance.hasStarted) {
            Shapes().drawCircle(pos: scale2dPoint(point: SIMD2<UInt32>(UInt32(Project.viewFrame.width/2 - 36), UInt32(Project.viewFrame.height/2 - 18)), oldSize: Project.viewFrame, newSize: drawableSize), radius: UInt32(115), color: &Project.backgroundColor, texture: &self.wallsTexture)
        }
        
        self.compTexture = overlayTextures(base: self.borderTexture, layers: self.wallsTexture)
        
        if(UserControl.instance.wallKeyPoints.count >= 1) {
            UserControl.instance.wallKeyPoints = [UserControl.instance.wallKeyPoints.last!]
            self.edgesTexture = findEdges(sourceTexture: self.compTexture)
        }
        
        var renderReady: MTLTexture
        if(UserControl.instance.showingEdges) {
            renderReady = overlayTextures(base: self.baseTrailsTexture, layers: self.edgesTexture)
        } else {
            renderReady = overlayTextures(base: self.baseTrailsTexture, layers: self.compTexture)
        }
        
        if let drawable = view.currentDrawable, 
            let commandBuffer = MetalObjects.commandQueue!.makeCommandBuffer(),
           let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            self.drawableSize = CGSize(width: drawable.texture.width, height: drawable.texture.height)
            
            renderReady = scaleImage(newSize: drawableSize, texture: renderReady)
            
            let origin = MTLOriginMake(0, 0, 0)
            let size = MTLSizeMake(
                renderReady.width, 
                renderReady.height, 
                1)
            blitEncoder.copy(from:renderReady, 
                             sourceSlice: 0, 
                             sourceLevel: 0,
                             sourceOrigin: origin, sourceSize: size,
                             to: drawable.texture, destinationSlice: 0,
                             destinationLevel: 0, destinationOrigin: origin)
            blitEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}

