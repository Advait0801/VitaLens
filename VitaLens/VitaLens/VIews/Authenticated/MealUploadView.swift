//
//  MealUploadView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MealUploadView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = MealUploadViewModel()
    @State private var showFileImporter: Bool = false
    
    // Supported file types
    private let allowedContentTypes: [UTType] = [
        .image,
        .jpeg,
        .png,
        .gif,
        .bmp,
        .pdf,
        .commaSeparatedText
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        // Header
//                        Text("Upload Meal")
//                            .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .bold))
//                            .foregroundColor(Colors.textPrimary)
//                            .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
//                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // File Selection Section
                        VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)) {
                            Text("Select File")
                                .font(.headline)
                                .foregroundColor(Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if viewModel.selectedFileURL != nil {
                                // Selected File Card
                                HStack(spacing: 16) {
                                    Image(systemName: viewModel.getFileIcon())
                                        .font(.system(size: 40))
                                        .foregroundColor(Colors.primary)
                                        .frame(width: 60, height: 60)
                                        .background(Colors.primary.opacity(0.1))
                                        .cornerRadius(12)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(viewModel.getFileName() ?? "Unknown")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Colors.textPrimary)
                                        
                                        if let fileSize = viewModel.getFileSize() {
                                            Text(fileSize)
                                                .font(.caption)
                                                .foregroundColor(Colors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.selectedFileURL = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Colors.textSecondary)
                                    }
                                }
                                .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                                .background(Colors.surface)
                                .cornerRadius(12)
                            } else {
                                // File Picker Button
                                Button(action: {
                                    showFileImporter = true
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(Colors.primary)
                                        
                                        Text("Choose File")
                                            .font(.headline)
                                            .foregroundColor(Colors.textPrimary)
                                        
                                        Text("Images, PDFs, or CSV files")
                                            .font(.caption)
                                            .foregroundColor(Colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, LayoutHelper.adaptivePadding(horizontalSizeClass, base: 40))
                                    .background(Colors.surface)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .background(Colors.surface)
                        .cornerRadius(16)
                        
                        // Meal Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meal Type")
                                .font(.headline)
                                .foregroundColor(Colors.textPrimary)
                            
                            Picker("Meal Type", selection: $viewModel.selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .background(Colors.surface)
                        .cornerRadius(16)
                        
                        // Meal Date Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meal Date")
                                .font(.headline)
                                .foregroundColor(Colors.textPrimary)
                            
                            DatePicker(
                                "Meal Date",
                                selection: $viewModel.selectedMealDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .accentColor(Colors.primary)
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .background(Colors.surface)
                        .cornerRadius(16)
                        
                        // Upload Progress
                        if viewModel.isUploading {
                            VStack(spacing: 12) {
                                ProgressView(value: viewModel.uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Colors.primary))
                                
                                Text("\(Int(viewModel.uploadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(Colors.textSecondary)
                            }
                            .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                            .background(Colors.surface)
                            .cornerRadius(16)
                        }
                        
                        // Success Message
                        if viewModel.showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Colors.success)
                                Text("Meal uploaded successfully!")
                                    .foregroundColor(Colors.success)
                            }
                            .padding()
                            .background(Colors.success.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Error Message
                        if viewModel.showError, let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Colors.error)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Colors.error.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Upload Button
                        Button(action: {
                            Task {
                                await viewModel.uploadFile()
                            }
                        }) {
                            HStack {
                                if viewModel.isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Upload Meal")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.selectedFileURL != nil && !viewModel.isUploading ? Colors.primary : Colors.textSecondary.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.selectedFileURL == nil || viewModel.isUploading)
                        .frame(maxWidth: LayoutHelper.isIPad(horizontalSizeClass) ? 400 : .infinity)
                        .padding(.top, LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 8))
                        .padding(.bottom, LayoutHelper.adaptivePadding(horizontalSizeClass))
                    }
                    .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.background)
            }
            .navigationTitle("Upload Meal")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Start accessing security-scoped resource
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessing {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        
                        // Copy file to app's temporary directory for upload
                        do {
                            let tempDir = FileManager.default.temporaryDirectory
                            let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)
                            
                            // Remove existing file if any
                            try? FileManager.default.removeItem(at: tempURL)
                            
                            // Copy file
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            viewModel.selectedFileURL = tempURL
                        } catch {
                            viewModel.errorMessage = "Failed to access file: \(error.localizedDescription)"
                            viewModel.showError = true
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
                    viewModel.showError = true
                }
            }
        }
    }
}
