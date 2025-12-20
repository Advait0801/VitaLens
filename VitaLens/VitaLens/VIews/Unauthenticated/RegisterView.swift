//
//  RegisterView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingLogin: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case username
        case password
        case confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                    // Header
                    Text("VitaLens")
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 48 : 34, weight: .bold))
                        .foregroundColor(Colors.primary)
                        .padding(.top, LayoutHelper.isIPad(horizontalSizeClass) ? 60 : 40)
                    
                    Text("Register")
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 28 : 22))
                        .foregroundColor(Colors.textSecondary)
                    
                    Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 30))
                    
                    // Form Fields
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            TextField("Enter email", text: $viewModel.email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .username
                                }
                        }
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            TextField("Enter username", text: $viewModel.username)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            SecureField("Enter password", text: $viewModel.password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .confirmPassword
                                }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            SecureField("Confirm password", text: $viewModel.confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task {
                                        await viewModel.register()
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: LayoutHelper.isIPad(horizontalSizeClass) ? 400 : .infinity)
                    
                    // Error Message
                    if viewModel.showError, let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(Colors.error)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 20))
                    
                    // Register Button
                    Button(action: {
                        Task {
                            await viewModel.register()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Register")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                    .frame(maxWidth: LayoutHelper.isIPad(horizontalSizeClass) ? 400 : .infinity)
                    
                    // Login Link
                    Button(action: {
                        showingLogin = true
                    }) {
                        Text("Already have an account? Login")
                            .font(.body)
                            .foregroundColor(Colors.primary)
                    }
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
    }
}
