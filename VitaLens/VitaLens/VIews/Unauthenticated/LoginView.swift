//
//  LoginView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingLogin: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var showPassword: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    enum Field {
        case usernameOrEmail
        case password
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
                    
                    Text("Login")
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 28 : 22))
                        .foregroundColor(Colors.textSecondary)
                    
                    Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 40))
                    
                    // Form Fields
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)) {
                        // Username/Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username or Email")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            TextField("Enter username or email", text: $viewModel.usernameOrEmail)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .usernameOrEmail)
                                .submitLabel(.next)
                                .onSubmit {
                                    if let error = viewModel.validateField(.usernameOrEmail) {
                                        alertMessage = error
                                        showAlert = true
                                    } else {
                                        focusedField = .password
                                    }
                                }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                            
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Enter password", text: $viewModel.password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("Enter password", text: $viewModel.password)
                                            .textContentType(.password)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(Colors.surface)
                            .foregroundColor(Colors.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                            .submitLabel(.go)
                            .onSubmit {
                                if let error = viewModel.validateField(.password) {
                                    alertMessage = error
                                    showAlert = true
                                } else {
                                    focusedField = nil
                                    Task {
                                        await viewModel.login()
                                    }
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
                    
                    // Login Button
                    Button(action: {
                        focusedField = nil
                        if let error = viewModel.validateField(.usernameOrEmail) {
                            alertMessage = error
                            showAlert = true
                        } else if let error = viewModel.validateField(.password) {
                            alertMessage = error
                            showAlert = true
                        } else {
                            Task {
                                await viewModel.login()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Login")
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
                    
                    // Register Link
                    Button(action: {
                        showingLogin = false
                    }) {
                        Text("Don't have an account? Register")
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
            .onTapGesture {
                focusedField = nil
            }
            .alert("Validation Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Colors.surface)
            .foregroundColor(Colors.textPrimary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Colors.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}
