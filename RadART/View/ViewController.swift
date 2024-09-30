//
//  ViewController.swift
//  RadART
//
//  Created by R. Metehan GÖKTAŞ on 7.02.2024.
//

import UIKit
import SwiftUI

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    let viewModel = ImageViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        
        imagePicker.delegate = self
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        // UIImageView
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        imageView.layer.borderWidth = 2.0
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowOffset = CGSize(width: 4, height: 4)
        imageView.layer.shadowRadius = 5
        view.addSubview(imageView)
        
        let selectButton = UIButton(type: .system)
        selectButton.setTitle("Pick Photo", for: .normal)
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.backgroundColor = UIColor.black
        selectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        selectButton.layer.cornerRadius = 10
        selectButton.addTarget(self, action: #selector(selectImageFromGallery(_:)), for: .touchUpInside)
        
        let detectButton = UIButton(type: .system)
        detectButton.setTitle("Detect", for: .normal)
        detectButton.setTitleColor(.white, for: .normal)
        detectButton.backgroundColor = UIColor.black
        detectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        detectButton.layer.cornerRadius = 10
        detectButton.addTarget(self, action: #selector(detectButtonTapped(_:)), for: .touchUpInside)
        
        let buttonStackView = UIStackView(arrangedSubviews: [selectButton, detectButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -40),
            
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            buttonStackView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    func setupBindings() {
        viewModel.onPredictionsUpdated = { [weak self] predictions in
            self?.showPredictions(predictions)
        }
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
        guard let pickedImage = imageView.image else {
            print("Önce bir fotoğraf seçiniz.")
            return
        }
        viewModel.sendImageToServer(image: pickedImage)
    }
    
    func showPredictions(_ predictions: [Prediction]) {
        // İlk üç tahmin
        let topPredictions = predictions.prefix(3)

        var resultText = ""
        for (index, prediction) in topPredictions.enumerated() {
            let percentage = Int(prediction.confidence * 100)
            resultText += "\(index + 1). \(prediction.label): \(percentage)%\n"
        }
        
        // Kullanıcıya sonucu göstermek için alert
        let alertController = UIAlertController(title: "Top Predictions", message: resultText, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

}

struct ViewController_Preview: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable().edgesIgnoringSafeArea(.all)
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}
