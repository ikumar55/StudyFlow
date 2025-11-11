//
//  PhotoManager.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import Foundation
import UIKit
import SwiftUI

/// Manages photo storage, compression, and file operations for StudyFlow
class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    
    private let fileManager = FileManager.default
    private let photosDirectory: URL
    
    // Photo constraints
    static let maxPhotosPerCard = 5
    static let maxPhotoSizeBytes = 5 * 1024 * 1024 // 5MB
    static let compressionQuality: CGFloat = 0.8
    
    private init() {
        // Create photos directory in app's documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("StudyFlowPhotos")
        
        createPhotosDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createPhotosDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            do {
                try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
                print("PhotoManager: Created photos directory at \(photosDirectory.path)")
            } catch {
                print("PhotoManager: Error creating photos directory: \(error)")
            }
        }
    }
    
    // MARK: - Photo Storage
    
    /// Saves a UIImage to the photos directory and returns the file path
    func savePhoto(_ image: UIImage) -> String? {
        let fileName = generateUniqueFileName()
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        guard let compressedData = compressImage(image) else {
            print("PhotoManager: Failed to compress image")
            return nil
        }
        
        do {
            try compressedData.write(to: fileURL)
            print("PhotoManager: Saved photo to \(fileName)")
            return fileName // Return just the filename, not full path
        } catch {
            print("PhotoManager: Error saving photo: \(error)")
            return nil
        }
    }
    
    /// Loads a UIImage from the photos directory using the file path
    func loadPhoto(from fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("PhotoManager: Photo file not found: \(fileName)")
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Deletes a photo file from storage
    func deletePhoto(_ fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("PhotoManager: Deleted photo: \(fileName)")
        } catch {
            print("PhotoManager: Error deleting photo: \(error)")
        }
    }
    
    // MARK: - Photo Processing
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize if too large
        let resizedImage = resizeImageIfNeeded(image)
        
        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: Self.compressionQuality)
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1920 // Max width or height
        let size = image.size
        
        // If image is already small enough, return as-is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // MARK: - Utility Methods
    
    private func generateUniqueFileName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "photo_\(timestamp)_\(uuid).jpg"
    }
    
    /// Gets the total size of all stored photos in bytes
    func getTotalPhotoStorageSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return files.reduce(Int64(0)) { total, fileURL in
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(fileSize)
            }
        } catch {
            print("PhotoManager: Error calculating storage size: \(error)")
            return 0
        }
    }
    
    /// Cleans up orphaned photos (photos not referenced by any flashcard)
    func cleanupOrphanedPhotos(referencedPhotos: Set<String>) {
        do {
            let allFiles = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in allFiles {
                let fileName = fileURL.lastPathComponent
                if !referencedPhotos.contains(fileName) {
                    try fileManager.removeItem(at: fileURL)
                    print("PhotoManager: Cleaned up orphaned photo: \(fileName)")
                }
            }
        } catch {
            print("PhotoManager: Error during cleanup: \(error)")
        }
    }
    
    // MARK: - Validation
    
    /// Checks if adding another photo would exceed the limit
    func canAddPhoto(to existingPhotos: [String]) -> Bool {
        return existingPhotos.count < Self.maxPhotosPerCard
    }
    
    /// Validates photo file size
    func isPhotoSizeValid(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return false }
        return data.count <= Self.maxPhotoSizeBytes
    }
}

// MARK: - Photo Storage Statistics
extension PhotoManager {
    struct StorageInfo {
        let totalPhotos: Int
        let totalSizeBytes: Int64
        let totalSizeMB: Double
        
        var formattedSize: String {
            if totalSizeMB < 1 {
                return String(format: "%.1f KB", Double(totalSizeBytes) / 1024)
            } else {
                return String(format: "%.1f MB", totalSizeMB)
            }
        }
    }
    
    func getStorageInfo() -> StorageInfo {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.reduce(Int64(0)) { total, fileURL in
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(fileSize)
            }
            
            return StorageInfo(
                totalPhotos: files.count,
                totalSizeBytes: totalSize,
                totalSizeMB: Double(totalSize) / (1024 * 1024)
            )
        } catch {
            print("PhotoManager: Error getting storage info: \(error)")
            return StorageInfo(totalPhotos: 0, totalSizeBytes: 0, totalSizeMB: 0)
        }
    }
}
