import SwiftUI

public class UserControl: ObservableObject {
    @Published public var showingEdges = false
    @Published public var isErasing = false
    @Published public var wallKeyPoints: Array<CGPoint> = []
    @Published public var simPaused: Bool = true
    @Published public var hasStarted: Bool = false
    
    public static var instance = UserControl()
}
