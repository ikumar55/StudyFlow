//
//  PhotoPicker.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import SwiftUI
import PhotosUI
import UIKit

/// Reusable component for adding and managing photos in flashcards
struct PhotoPicker: View {
    @Binding var photos: [String] // Array of photo file names
    let title: String
    let maxPhotos: Int = PhotoManager.maxPhotosPerCard
    
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingPhotoLibrary = false
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if photos.count < maxPhotos {
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                            Text("Add Photo")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Photo grid
            if !photos.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photoFileName in
                        PhotoThumbnailView(
                            photoFileName: photoFileName,
                            onDelete: {
                                deletePhoto(at: index)
                            }
                        )
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No photos added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Add First Photo") {
                        showingActionSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Photo count indicator
            if !photos.isEmpty {
                HStack {
                    Text("\(photos.count) of \(maxPhotos) photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if photos.count >= maxPhotos {
                        Text("Maximum reached")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Camera") {
                imagePickerSourceType = .camera
                showingImagePicker = true
            }
            
            Button("Photo Library") {
                showingPhotoLibrary = true
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                addPhoto(image)
            }
        }
        .photosPicker(
            isPresented: $showingPhotoLibrary,
            selection: $selectedItems,
            maxSelectionCount: maxPhotos - photos.count,
            matching: .images
        )
        .onChange(of: selectedItems) {
            Task {
                await loadSelectedPhotos()
            }
        }
    }
    
    // MARK: - Photo Management
    
    private func addPhoto(_ image: UIImage) {
        guard photos.count < maxPhotos else {
            print("PhotoPicker: Maximum photos reached")
            return
        }
        
        guard PhotoManager.shared.isPhotoSizeValid(image) else {
            print("PhotoPicker: Photo size too large")
            return
        }
        
        if let fileName = PhotoManager.shared.savePhoto(image) {
            photos.append(fileName)
            HapticFeedback.success()
        } else {
            HapticFeedback.error()
        }
    }
    
    private func deletePhoto(at index: Int) {
        guard index < photos.count else { return }
        
        let fileName = photos[index]
        PhotoManager.shared.deletePhoto(fileName)
        photos.remove(at: index)
        HapticFeedback.light()
    }
    
    private func loadSelectedPhotos() async {
        for item in selectedItems {
            guard photos.count < maxPhotos else { break }
            
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        addPhoto(image)
                    }
                }
            } catch {
                print("PhotoPicker: Error loading photo: \(error)")
            }
        }
        
        await MainActor.run {
            selectedItems.removeAll()
        }
    }
}

// MARK: - Photo Thumbnail View
struct PhotoThumbnailView: View {
    let photoFileName: String
    let onDelete: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo thumbnail
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
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.red, in: Circle())
            }
            .offset(x: 6, y: -6)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        image = PhotoManager.shared.loadPhoto(from: photoFileName)
    }
}

// MARK: - UIImagePickerController Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var photos: [String] = []
        
        var body: some View {
            NavigationView {
                Form {
                    Section {
                        PhotoPicker(photos: $photos, title: "Question Photos")
                    }
                }
                .navigationTitle("Photo Picker Preview")
            }
        }
    }
    
    return PreviewWrapper()
}
