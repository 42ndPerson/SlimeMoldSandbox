import SwiftUI
import MetalKit

struct ContentView: View {
    @ObservedObject var uiControl = UserControl.instance
    
    @State var displayingInfo = true
    @State var started: Bool = true
    @State var settingsOpen: Bool = false
    
    let sandboxView = SandboxView()
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
            self.sandboxView.equatable()
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Button(action: {
                        UserControl.instance.simPaused = false
                        UserControl.instance.hasStarted = true
                    }, label: {
                        Text("Start")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 50, alignment: .center)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(.white, lineWidth: 3, antialiased: true)
                            }
                    })
                    .padding()
                    Spacer()
                    VStack {
                        Button(action: {
                            withAnimation(.default) { 
                                settingsOpen.toggle()
                            }
                        }, label: {
                            HStack {
                                Text("Settings")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: self.settingsOpen ? "chevron.down" : "chevron.forward")
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                        })
                        if(self.settingsOpen) {
                            VStack {
                                Toggle("Show Edges", isOn: $uiControl.showingEdges)
                                    .toggleStyle(.button)
                                    .foregroundColor(uiControl.showingEdges ? .green : .white)
                                    .background(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .foregroundStyle(.black)   
                                    }
                                    .overlay(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(.white, lineWidth: 1)
                                    }
                                Toggle("Erase", isOn: $uiControl.isErasing)
                                    .toggleStyle(.button)
                                    .foregroundColor(uiControl.isErasing ? .green : .white)
                                    .background(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .foregroundStyle(.black)   
                                    }
                                    .overlay(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(.white, lineWidth: 1)
                                    }
                                Toggle("Pause", isOn: $uiControl.simPaused)
                                    .toggleStyle(.button)
                                    .foregroundColor(uiControl.simPaused ? .green : .white)
                                    .background(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .foregroundStyle(.black)   
                                    }
                                    .overlay(alignment: .center) { 
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(.white, lineWidth: 1)
                                    }
                                Button(action: {
                                    self.sandboxView.setupEntities()
                                }, label: {
                                    Text("Reset Sim")
                                })
                                    .padding()
                                Button(action: {
                                    self.displayingInfo = true;
                                }, label: {
                                    Text("Show Info")
                                })
                                    .padding(.bottom)
                            }
                        }
                    }
                        .frame(maxWidth: 200)
                        .padding(7)
                        .background(alignment: .center) { 
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white, lineWidth: 2)
                                .foregroundColor(.black)
                        }
                        .padding(10)
                }
            }
            if(self.displayingInfo) {
                VStack {
                    Text("Slime Mold Sandbox")
                        .font(.title)
                        .padding()
                        .foregroundColor(.white)
                    ScrollView() {
                        Text("    Slime molds are uniquely fascinating single celled organisms.  They occur world-wide, but despite their name, they are not actually a type of mold.  Several different types of organisms fall under the common ‘slime mold’ name, but of particular note is a type of protist called Physarum polycephalum.  These slime molds form intricate and fascinating patterns as they grow.  You may have spotted them occasionally appearing in the news as a goopy yellow maze solver. \n    I had encountered several such articles by the time I happened across [this project](https://youtu.be/X-iSQQgOd1A) by Sebastian Lague.  He builds a GPU-based slime mold simulation based on [a paper](https://uwe-repository.worktribe.com/output/980579) by Jeff Jones at the University of the West of England.  The serene beauty of the evolving forms transfixed me; I found it peaceful and calming, but I wanted a way to interact with it.  At the time I was curious about learning GPU programming, so I built my own version of Lague's simulation in Metal.  I then worked to add drawable walls, so you can shape the environment the slime mold explores and control its flow. \n    The effect works by simulating hundreds of thousands of entities, shown as little white dots; they leave trails as they move and try to follow each other's trails.  As for the walls, they are merely a texture, but I used a technique called [Sobel edge detector](https://en.wikipedia.org/wiki/Sobel_operator) to determine the deflection angles for colliding slime.  You can peek under the hood and view the edges through the settings pane. \n    Once you click \"Let's Go\" below you will be able to click and drag to draw walls before clicking start to kick things off.  **Try letting the slime mold explore uninhibited for a bit, maybe build it a little maze to work through, and especially try drawing a wall through an established connection to see how it reacts.  But overall, this is a sandbox to explore and delight in.  Enjoy!**")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                        .padding()
                    Button(action: {
                        withAnimation { 
                            self.displayingInfo = false
                        }
                    }, label: {
                        Text("Let's Go")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 50, alignment: .center)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(.white, lineWidth: 3, antialiased: true)
                            }
                    })
                        .padding()
                }
                    .frame(width: 700, height: 800, alignment: .center)
                    .background(alignment: .center) { 
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white, lineWidth: 2)
                            .foregroundColor(.black)
                    }
                    .background(.black)
                    .cornerRadius(20, antialiased: true)
                    .zIndex(.greatestFiniteMagnitude)
                    .transition(.move(edge: .bottom))
            }
        }
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .global)
                    .onChanged { value in
                        UserControl.instance.wallKeyPoints.append(CGPoint(x: value.location.x, y: value.location.y-35))
                    }
                    .onEnded { value in
                        UserControl.instance.wallKeyPoints = []
                    }
            )
    }
}
