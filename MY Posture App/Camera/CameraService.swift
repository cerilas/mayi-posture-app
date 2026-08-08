import AVFoundation
import Combine

/// Service responsible for managing the camera session and providing frames for processing.
class CameraService: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isRunning = false
    @Published var cameraError: Error?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.myposture.camera.sessionQueue")
    
    var framePublisher = PassthroughSubject<CMSampleBuffer, Never>()
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            // Use front camera
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                }
                
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    
                    // Fix orientation so Vision receives correctly oriented frames
                    // Front camera in portrait mode requires .portrait rotation
                    if let connection = self.videoOutput.connection(with: .video) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    }
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
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        framePublisher.send(sampleBuffer)
    }
}
