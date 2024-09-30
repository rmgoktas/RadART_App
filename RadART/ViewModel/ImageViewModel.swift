//
//  ImageViewModel.swift
//  RadART
//
//  Created by R. Metehan GÖKTAŞ on 27.09.2024.
//

import UIKit

class ImageViewModel {

    var onPredictionsUpdated: (([Prediction]) -> Void)?

    func sendImageToServer(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Image compression failed")
            return
        }
        
        let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
        let json: [String: String] = ["image": base64String]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            print("JSON serialization failed")
            return
        }
        
        guard let url = URL(string: Config.serverURL) else {
            print("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("No data received: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let predictions = self.parsePredictions(from: data) {
                DispatchQueue.main.async {
                    self.onPredictionsUpdated?(predictions)
                }
            }
        }.resume()
    }
    
    private func parsePredictions(from data: Data) -> [Prediction]? {
        let decoder = JSONDecoder()
        do {
            let jsonResponse = try decoder.decode([String: [Prediction]].self, from: data)
            return jsonResponse["predictions"]?.sorted(by: { $0.confidence > $1.confidence })
        } catch {
            print("Failed to parse JSON: \(error.localizedDescription)")
            return nil
        }
    }
}
