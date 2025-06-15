//
//  CameraView.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void
    
    /// Creates and configures a `UIImagePickerController` for capturing photos using the front camera.
    ///
    /// - Parameter context: The context containing the coordinator for delegate callbacks.
    /// - Returns: A `UIImagePickerController` set up for front camera photo capture without editing.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .front // Default to front camera for selfies
        picker.allowsEditing = false
        return picker
    }
    
    /// Updates the presented image picker controller.
///
/// No updates are required for the image picker during its lifecycle.
func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    /// Creates a coordinator to handle image picker delegate callbacks for the camera view.
    ///
    /// - Returns: A `Coordinator` instance configured with the current `CameraView`.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        /// Handles the completion of image picking by invoking the image capture callback with the selected image and dismissing the picker.
        ///
        /// - Parameters:
        ///   - picker: The image picker controller instance.
        ///   - info: A dictionary containing information about the captured media.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.isPresented = false
        }
        
        /// Handles cancellation of the image picker by dismissing the camera view.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// Preview camera view for showing live feed
struct CameraPreviewView: UIViewRepresentable {
    @State private var captureSession = AVCaptureSession()
    
    /// Creates and configures a UIView displaying a live preview from the front camera.
    ///
    /// The returned view contains an `AVCaptureVideoPreviewLayer` showing the camera feed in aspect fill mode. If the camera cannot be accessed or configured, an empty view is returned.
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return view
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            captureSession.startRunning()
        } catch {
            print("Camera preview error: \(error)")
        }
        
        return view
    }
    
    /// Updates the camera preview view. No action is required as the preview does not need to be updated after creation.
func updateUIView(_ uiView: UIView, context: Context) {}
} 