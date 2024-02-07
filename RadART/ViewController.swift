//
//  ViewController.swift
//  RadART
//
//  Created by R. Metehan GÖKTAŞ on 7.02.2024.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imageView: UIImageView!
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIImageView oluşturuluyor
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // UIImageView'a layoutConstraints uygulanıyor
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
        
        // "Fotoğraf Seç" adında bir buton oluşturuluyor
        let selectButton = UIButton(type: .system)
        selectButton.setTitle("Fotoğraf Seç", for: .normal)
        selectButton.addTarget(self, action: #selector(selectImageFromGallery(_:)), for: .touchUpInside)
        
        // "Fotoğraf Seç" butonuna layoutConstraints uygulanıyor
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // "Detect" adında bir buton oluşturuluyor
        let detectButton = UIButton(type: .system)
        detectButton.setTitle("Detect", for: .normal)
        detectButton.addTarget(self, action: #selector(detectButtonTapped(_:)), for: .touchUpInside)
        
        // "Detect" butonuna layoutConstraints uygulanıyor
        detectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detectButton)
        NSLayoutConstraint.activate([
            detectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detectButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140)
        ])
        
        imagePicker.delegate = self
    }

    @objc func selectImageFromGallery(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            imageView.image = pickedImage
            dismiss(animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func detectButtonTapped(_ sender: UIButton) {
        if let pickedImage = imageView.image {
            if let imageData = pickedImage.jpegData(compressionQuality: 0.5) {
                let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
                sendImageToServer(base64String: base64String)
            }
        } else {
            print("Önce bir fotoğraf seçiniz.")
        }
    }
    
    func sendImageToServer(base64String: String) {
        let json: [String: String] = ["image": base64String]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        let url = URL(string: Config.serverURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("No data received: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let result = String(data: data, encoding: .utf8) {
                print("Server response: \(result)")
                // Handle server response here
                self.parsePredictions(from: result)
            }
        }.resume()
    }

    func parsePredictions(from jsonString: String) {
        // JSON verisini dize olarak parse etme
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("JSON verisi dönüştürülemedi.")
            return
        }

        // JSON verisini objeye dönüştürme
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            print("JSON objesi oluşturulamadı.")
            return
        }

        // Tahminlerin bulunduğu kısmı alma
        guard let predictions = jsonObject["predictions"] as? [[String: Any]] else {
            print("Tahminler bulunamadı.")
            return
        }

        // Tahminleri güvenilirlik oranına göre sıralama
        let sortedPredictions = predictions.sorted { ($0["confidence"] as? Double ?? 0.0) > ($1["confidence"] as? Double ?? 0.0) }

        // En yüksek üç tahmini ve güvenilirlik oranlarını ekrana yazdırma
        var displayPredictions: [(label: String, confidence: Double)] = []
        for (_, prediction) in sortedPredictions.prefix(3).enumerated() {
            if let label = prediction["label"] as? String, let confidence = prediction["confidence"] as? Double {
                displayPredictions.append((label, confidence))
            }
        }
        DispatchQueue.main.async {
            self.showPredictions(displayPredictions)
        }
    }

    func showPredictions(_ predictions: [(label: String, confidence: Double)]) {
        var resultText = ""
        for (index, prediction) in predictions.enumerated() {
            let percentage = Int(prediction.confidence * 100)
            resultText += "\(index + 1). \(prediction.label): \(percentage)%\n"
        }
        let alertController = UIAlertController(title: "Predictions", message: resultText, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
