//
//  PhotoViewer.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import SwiftUI

/// Full-screen photo viewer with zoom and pan capabilities for study sessions
struct PhotoViewer: View {
    let photoFileNames: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    init(photoFileNames: [String], initialIndex: Int = 0) {
        self.photoFileNames = photoFileNames
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if !photoFileNames.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photoFileNames.enumerated()), id: \.offset) { index, fileName in
                            ZoomablePhotoView(
                                photoFileName: fileName,
                                scale: $scale,
                                offset: $offset,
                                lastScale: $lastScale,
                                lastOffset: $lastOffset
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) {
                        // Reset zoom when switching photos
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scale = 1.0
                            offset = .zero
                            lastScale = 1.0
                            lastOffset = .zero
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if photoFileNames.count > 1 {
                        Text("\(currentIndex + 1) of \(photoFileNames.count)")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Zoomable Photo View
struct ZoomablePhotoView: View {
    let photoFileName: String
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                // Magnification gesture for zooming
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = scale
                                        
                                        // Limit zoom levels
                                        if scale < 1.0 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                scale = 1.0
                                                lastScale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        } else if scale > 5.0 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                scale = 5.0
                                                lastScale = 5.0
                                            }
                                        }
                                    },
                                
                                // Drag gesture for panning
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                        
                                        // Constrain offset to keep image visible
                                        let maxOffset = calculateMaxOffset(geometry: geometry)
                                        
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            offset.width = max(-maxOffset.width, min(maxOffset.width, offset.width))
                                            offset.height = max(-maxOffset.height, min(maxOffset.height, offset.height))
                                            lastOffset = offset
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to zoom
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                } else {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading photo...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        image = PhotoManager.shared.loadPhoto(from: photoFileName)
    }
    
    private func calculateMaxOffset(geometry: GeometryProxy) -> CGSize {
        guard let image = image else { return .zero }
        
        let imageSize = image.size
        let containerSize = geometry.size
        
        // Calculate the displayed image size (aspect fit)
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        let displayedSize: CGSize
        if imageAspect > containerAspect {
            // Image is wider - fit to width
            displayedSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
        } else {
            // Image is taller - fit to height
            displayedSize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
        }
        
        // Calculate scaled size
        let scaledSize = CGSize(
            width: displayedSize.width * scale,
            height: displayedSize.height * scale
        )
        
        // Calculate maximum offset to keep image in bounds
        let maxOffsetX = max(0, (scaledSize.width - containerSize.width) / 2)
        let maxOffsetY = max(0, (scaledSize.height - containerSize.height) / 2)
        
        return CGSize(width: maxOffsetX, height: maxOffsetY)
    }
}

// MARK: - Photo Grid View (for study sessions)
struct PhotoGridView: View {
    let photoFileNames: [String]
    let columns: Int
    @State private var selectedPhotoIndex: Int?
    
    init(photoFileNames: [String], columns: Int = 2) {
        self.photoFileNames = photoFileNames
        self.columns = columns
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(Array(photoFileNames.enumerated()), id: \.offset) { index, fileName in
                PhotoThumbnailButton(
                    photoFileName: fileName,
                    onTap: {
                        selectedPhotoIndex = index
                    }
                )
            }
        }
        .fullScreenCover(item: Binding<Int?>(
            get: { selectedPhotoIndex },
            set: { selectedPhotoIndex = $0 }
        )) { index in
            PhotoViewer(photoFileNames: photoFileNames, initialIndex: index)
        }
    }
}

// MARK: - Photo Thumbnail Button
struct PhotoThumbnailButton: View {
    let photoFileName: String
    let onTap: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        image = PhotoManager.shared.loadPhoto(from: photoFileName)
    }
}

// Helper extension to make Int? identifiable for fullScreenCover
extension Int: Identifiable {
    public var id: Int { self }
}

#Preview {
    PhotoViewer(photoFileNames: ["sample1.jpg", "sample2.jpg"], initialIndex: 0)
}
