//
//  ScanView.swift
//  FairShare
//
//  Receipt scanning screen with camera
//

import SwiftUI
import AVFoundation
import CoreImage

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var navigateToConfirm = false
    @State private var ocrResult: OCRResult?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Scanning receipt...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    CameraView(onFrameCaptured: { image in
                        viewModel.processVideoFrame(image)
                    })
                    .overlay(alignment: .top) {
                        ScanningOverlayView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            sourceType = .camera
                            showCamera = true
                        }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType) { image in
                    viewModel.processImage(image)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    viewModel.processImage(image)
                }
            }
            .onChange(of: viewModel.scanningState) { _, newState in
                if newState == .preview, let result = viewModel.scanResult {
                    ocrResult = result
                    navigateToConfirm = true
                }
            }
            .navigationDestination(isPresented: $navigateToConfirm) {
                if let result = ocrResult {
                    ConfirmReceiptView(ocrResult: result, isPreviewMode: true, onRetry: {
                        viewModel.resetScanning()
                        navigateToConfirm = false
                    })
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onFrameCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onFrameCaptured = onFrameCaptured
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var onFrameCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.fairshare.videoQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            session.startRunning()
        }
        updatePreviewLayerFrame()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayerFrame()
    }
    
    private func updatePreviewLayerFrame() {
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(input) else {
            return
        }
        
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.videoOutput = output
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.captureSession = session
        self.previewLayer = previewLayer
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.onFrameCaptured?(image)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ScanningOverlayView: View {
    @ObservedObject var viewModel: ScanViewModel
    
    var body: some View {
        VStack {
            // State indicator text
            if viewModel.scanningState != .idle && viewModel.scanningState != .preview {
                Text(stateMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(.top, 20)
            }
            
            Spacer()
            
            // Visual indicator for detected receipt
            if viewModel.scanningState == .receiptCandidateDetected || viewModel.scanningState == .stableReceiptConfirmed {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.scanningState == .stableReceiptConfirmed ? .green : .blue)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    if viewModel.scanningState == .stableReceiptConfirmed {
                        Text("Hold steady...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    private var stateMessage: String {
        switch viewModel.scanningState {
        case .idle:
            return ""
        case .searchingForReceipt:
            return "Searching for receipt..."
        case .receiptCandidateDetected:
            return "Receipt detected"
        case .stableReceiptConfirmed:
            return "Hold steady..."
        case .capturedAndProcessing:
            return "Processing..."
        case .preview:
            return ""
        }
    }
}

