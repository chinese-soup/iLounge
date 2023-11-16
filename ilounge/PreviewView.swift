//
//  PreviewView.swift
//  liff
//
//  Created by Jakub Mach on 06.11.2023.
//

import SwiftUI

struct PreviewView: View {
    @Binding var isPreviewViewVisible: Bool
    @Binding var imageURL: String
    
    @State private var scale: Double = 1.0
    @State private var lastScale: Double = 1.0
    
    var body: some View {
        AsyncImage(
          url: URL(
            string: imageURL
            ))
        { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.0)) // Lol, get rid of this
                        .frame(height: 240)
                    VStack {
                        ProgressView {
                            Text("Loading image")
                                .foregroundColor(.gray)
                                .bold()
                        }
                        // Image(systemName: "photo")
                    }
                }
            case .success(let image):
                image.resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .ignoresSafeArea()
                    .frame(height: 240)
                    .gesture(MagnificationGesture().onChanged { val in
                            let delta = val / self.lastScale
                            self.lastScale = val
                            let newScale = self.scale * delta
                            self.scale = newScale
                        }.onEnded { _ in
                            self.lastScale = 1.0
                        })
            case .failure(_):
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.0)) // Lol, get rid of this
                        .frame(height: 240)
                    VStack(alignment: .center) {
                        Text("Failed to load image")
                            .foregroundColor(.red)
                            .bold()
                            .padding()
                        Link(destination: URL(string: imageURL)!) {
                            Text("\(imageURL)")
                                .padding()
                        }
                    }
                }
            @unknown default:
                Text("Unknown state, please report this as a bug.")
            }
          }
    }
}

/*#Preview {
    PreviewView()
}*/
