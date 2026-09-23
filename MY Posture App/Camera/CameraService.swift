import AVFoundation
import Combine
import CoreImage
import UIKit

/// Service responsible for managing the camera session and providing frames for processing.
class CameraService: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isRunning = false
    @Published var cameraError: Error?
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var isRecordingVideo = false
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.myposture.camera.sessionQueue")
    private var currentInput: AVCaptureDeviceInput?
    
    var framePublisher = PassthroughSubject<CMSampleBuffer, Never>()
    private var lastSampleBuffer: CMSampleBuffer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.currentInput = videoDeviceInput
                }
                
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    
                    if let connection = self.videoOutput.connection(with: .video) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    }
                }
                
                if self.session.canAddOutput(self.movieOutput) {
                    self.session.addOutput(self.movieOutput)
                }
                
                self.session.sessionPreset = .high
            } catch {
                DispatchQueue.main.async {
                    self.cameraError = error
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func switchCamera() {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            let targetPosition: AVCaptureDevice.Position = (self.cameraPosition == .front) ? .back : .front
            
            if let current = self.currentInput {
                self.session.removeInput(current)
            }
            
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: targetPosition) else {
                if let current = self.currentInput {
                    self.session.addInput(current)
                }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                    DispatchQueue.main.async {
                        self.cameraPosition = targetPosition
                    }
                } else if let current = self.currentInput {
                    self.session.addInput(current)
                }
                
                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
            } catch {
                if let current = self.currentInput {
                    self.session.addInput(current)
                }
                DispatchQueue.main.async {
                    self.cameraError = error
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    func takeSnapshot() -> UIImage? {
        guard let sampleBuffer = lastSampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Video Recording
    
    private var videoRecordingCompletion: ((URL?) -> Void)?
    
    func startVideoRecording() {
        sessionQueue.async {
            guard !self.movieOutput.isRecording else { return }
            
            // Set rotation for video recording
            if let connection = self.movieOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".mp4"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            self.movieOutput.startRecording(to: fileURL, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecordingVideo = true
            }
        }
    }
    
    func stopVideoRecording(completion: @escaping (URL?) -> Void) {
        sessionQueue.async {
            guard self.movieOutput.isRecording else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.videoRecordingCompletion = completion
            self.movieOutput.stopRecording()
            DispatchQueue.main.async {
                self.isRecordingVideo = false
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        lastSampleBuffer = sampleBuffer
        framePublisher.send(sampleBuffer)
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Video recording error: \(error!)")
            DispatchQueue.main.async {
                self.videoRecordingCompletion?(nil)
                self.videoRecordingCompletion = nil
            }
            return
        }
        
        // Compress video
        compressVideo(inputURL: outputFileURL) { compressedURL in
            DispatchQueue.main.async {
                self.videoRecordingCompletion?(compressedURL ?? outputFileURL)
                self.videoRecordingCompletion = nil
            }
        }
    }
    
    private func compressVideo(inputURL: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: inputURL)
        let preset: String
        if AVAssetExportSession.allExportPresets().contains(AVAssetExportPreset960x540) {
            preset = AVAssetExportPreset960x540
        } else {
            preset = AVAssetExportPresetMediumQuality
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(nil)
            return
        }
        
        let compressedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_compressed.mp4")
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                // Delete uncompressed original to save local space
                try? FileManager.default.removeItem(at: inputURL)
                completion(compressedURL)
            } else {
                print("[CameraService] Video compression failed: \(String(describing: exportSession.error))")
                // If compression failed, return original URL as fallback
                completion(inputURL)
            }
        }
    }
}
