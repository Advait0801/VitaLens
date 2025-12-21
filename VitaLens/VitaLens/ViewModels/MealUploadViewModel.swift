//
//  MealUploadViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/21/25.
//

import SwiftUI
internal import Combine

@MainActor
class MealUploadViewModel: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var selectedMealType: MealType = .other
    @Published var selectedMealDate: Date = Date()
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var showSuccess: Bool = false
    @Published var uploadedMeal: MealResponse?
    
    private let mealService = MealService.shared
    
    /// Upload selected file
    func uploadFile() async {
        guard let fileURL = selectedFileURL else {
            errorMessage = "Please select a file"
            showError = true
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        showError = false
        showSuccess = false
        
        // Start progress simulation
        let progressTask = Task {
            while isUploading && uploadProgress < 0.9 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if isUploading {
                    uploadProgress = min(uploadProgress + 0.05, 0.9)
                }
            }
        }
        
        do {
            let meal = try await mealService.uploadMeal(
                fileURL: fileURL,
                mealType: selectedMealType,
                mealDate: selectedMealDate
            ) { progress in
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            
            progressTask.cancel()
            uploadProgress = 1.0
            
            uploadedMeal = meal
            isUploading = false
            showSuccess = true
            
            // Clean up temporary file
            if let fileURL = selectedFileURL,
               fileURL.path.contains(FileManager.default.temporaryDirectory.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            // Reset after a delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            reset()
            
        } catch let error as MealError {
            progressTask.cancel()
            isUploading = false
            uploadProgress = 0.0
            errorMessage = error.errorDescription
            showError = true
        } catch {
            progressTask.cancel()
            isUploading = false
            uploadProgress = 0.0
            errorMessage = "Failed to upload file"
            showError = true
        }
    }
    
    /// Reset upload state
    func reset() {
        // Clean up temporary file if exists
        if let fileURL = selectedFileURL,
           fileURL.path.contains(FileManager.default.temporaryDirectory.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        selectedFileURL = nil
        selectedMealType = .other
        selectedMealDate = Date()
        uploadProgress = 0.0
        showSuccess = false
        uploadedMeal = nil
    }
    
    /// Get file name from URL
    func getFileName() -> String? {
        return selectedFileURL?.lastPathComponent
    }
    
    /// Get file size
    func getFileSize() -> String? {
        guard let fileURL = selectedFileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Get file type icon
    func getFileIcon() -> String {
        guard let fileName = getFileName() else { return "doc" }
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "bmp":
            return "photo"
        case "pdf":
            return "doc.fill"
        case "csv":
            return "tablecells"
        default:
            return "doc"
        }
    }
}
