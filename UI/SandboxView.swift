import SwiftUI
import MetalKit

struct SandboxView: UIViewRepresentable, Equatable {
    var mtkView: MTKView
    var delegate: SandboxDelegate
    
    static var hasStarted = false //Internal hasStarted tracks window refreshes rather than simple logical program restart
    
    init() {
        self.mtkView = MTKView(frame: CGRect(x: 0, y: 0, width: Project.viewFrame.width/2, height: Project.viewFrame.height/2))
        self.mtkView.isPaused = false
    
        self.delegate = SandboxDelegate(mtkView: self.mtkView)!
        self.mtkView.delegate = self.delegate
        
        if(!SandboxView.hasStarted) { 
            setupEntities() 
            SandboxView.hasStarted = true
        }
        
        UserControl.instance.simPaused = false
        self.delegate.draw(in: self.mtkView)
        UserControl.instance.simPaused = true
    }
    func setupEntities() {
        Project.entities.reserveCapacity(Project.entityCount)
        Project.entities = entitiesInit()
    }
    
    func makeUIView(context: UIViewRepresentableContext<SandboxView>) -> MTKView {
        return self.mtkView
    }
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<SandboxView>) {
        self.mtkView.delegate!.draw(in: self.mtkView)
    }
    
    static func == (lhs: SandboxView, rhs: SandboxView) -> Bool {
        return true
    }
}
