//
//  ViewController.swift
//  GameraAPP
//
//  Created by 井関竜太郎 on 2021/02/10.
//

import UIKit
import AVFoundation
import ImageIO


class ViewController: UIViewController, AVCapturePhotoCaptureDelegate,AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var takeButton: UIButton!
    @IBOutlet weak var changeButton: UIButton!
    
    
    //変数宣言
    //カメラの内外を変える。
    var cameraType: Bool = true
    //カメラとの接続を管理するもの。
    var captureSession: AVCaptureSession!
    //  写真を撮ったものを保存する。
    var photoOutput: AVCapturePhotoOutput!
    //イメージに変換して保存する。
    var cameraImage: UIImage!
    //おしゃべり機能
    var speech = AVSpeechSynthesizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //おしゃべり機能
        self.speech.delegate = self;
        
        //ボタンの設定
        self.buttonSetting(takePhoto: true, change: true, save: false, retake: false)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //カメラ接続
        self.cameraConnection(type: cameraType)
    }
    
    //カメラ接続〜映像表示
    func cameraConnection(type: Bool){
        //カメラの接続設定
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        photoOutput = AVCapturePhotoOutput()
        
        //フロントカメラ or バックカメラ
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        var device:AVCaptureDevice?
        if(type == true){
            device = frontCamera
        }else{
            device = backCamera
        }
        //映像表示
        do {
            let input = try AVCaptureDeviceInput(device: device!)
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                if (captureSession.canAddOutput(photoOutput)) {
                    captureSession.addOutput(photoOutput)
                    captureSession.startRunning()
                    let captureVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
                    captureVideoLayer.frame = self.cameraView.bounds
                    captureVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.cameraView.layer.addSublayer(captureVideoLayer)
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    
    //フロントカメラ・バックカメラの切り替え
    func changeCamera(){
        //いったんセッション切る
        captureSession.stopRunning()
        //カメラタイプを反転
        cameraType = !cameraType
        //再接続
        self.cameraConnection(type: cameraType)
    }
    
    //写真を撮る
    func takePhoto() {
        //ボタンの設定
        self.buttonSetting(takePhoto: false, change: false, save: true, retake: true)
        
        //撮影設定
        let photoSetting = AVCapturePhotoSettings()
        photoSetting.flashMode = .auto
      // photoSetting.isAutoStillImageStabilizationEnabled = true
        photoSetting.isHighResolutionPhotoEnabled = false
        photoOutput?.capturePhoto(with: photoSetting, delegate: self)
    }
    
    
    //写真出力
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        //キャプチャを止める
        self.captureSession.stopRunning()
        
        let photoData = photo.fileDataRepresentation()
        
        //JPEGからUIImageを作成
        self.cameraImage = UIImage(data: photoData!)
    }
    
    
    
    @IBAction func retake(_ sender: Any) {
        //セッション再開
        captureSession.startRunning()
        
        //ボタンの設定
        self.buttonSetting(takePhoto: true, change: true, save: false, retake: false)
    }
    
    @IBAction func save(_ sender: Any) {
        // その中の UIImage を取得
        let targetImage = self.cameraImage
        
        // UIImage の画像をカメラロールに写真を保存
        UIImageWriteToSavedPhotosAlbum(targetImage!, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    
    
    //カメラロールへの保存後の処理
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        //ダイアログに結果を表示
        var title = "保存完了"
        var message = "カメラロールに写真を保存しました"
        
        //エラー発生時のメッセージ
        if (error != nil) {
            title = "エラー"
            message = "写真の保存に失敗しました"
        }
        
        //ダイアログ表示
        alert(title: title, message: message)
        //セッション再開
        captureSession.startRunning()
        //ボタンの設定
        self.buttonSetting(takePhoto: true, change: true, save: false, retake: false)
    }
    
    //アラート表示
    func alert(title: String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action:UIAlertAction!) -> Void in }))
        
        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }

    
    
    
    @IBAction func take(_ sender: Any) {
        //ボタンの設定
        self.buttonSetting(takePhoto: false, change: false, save: true, retake: true)
        speak(message: "はい、チーズ！！")
    }
    
    @IBAction func change(_ sender: Any) {
        changeCamera();
    }
    

    
    
    
    func speak(message:String) {
        let utterance = AVSpeechUtterance(string: message as String)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        self.speech.speak(utterance)
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("開始")
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("終了")
        self.takePhoto()
    }
    
    
    func buttonSetting(takePhoto:Bool,change:Bool,save:Bool,retake:Bool) {
        self.takeButton.isEnabled = takePhoto
        self.changeButton.isEnabled = change
        self.saveButton.isEnabled = save
        self.retakeButton.isEnabled = retake
    }
    
    
    
  
    
}

