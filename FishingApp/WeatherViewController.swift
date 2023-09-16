//
//  WetherViewController.swift
//  FishingApp
//
//  Created by 待寺翼 on 2023/09/15.
//
import UIKit
import MapKit

class WeatherViewController: UIViewController, MKMapViewDelegate {
    
    let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    let weatherTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }()
    
    let apiKey = "5d3ae33b20fa31c74bf3ed56490e389b"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
    }
    
    func setupUI() {
        view.addSubview(mapView)
        view.addSubview(weatherTextView)
        
        mapView.delegate = self
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            weatherTextView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 8),
            weatherTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            weatherTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            weatherTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }
    
    func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        fetchWeatherData(for: coordinate)
    }
    
    func fetchWeatherData(for coordinate: CLLocationCoordinate2D) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error:", error.localizedDescription)
                    return
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let main = json["main"] as? [String: Any],
                           let weatherArray = json["weather"] as? [[String: Any]],
                           let weather = weatherArray.first,
                           let wind = json["wind"] as? [String: Any],
                           let sys = json["sys"] as? [String: Any] {
                            
                            let description = weather["description"] as? String ?? ""
                            let mainWeather = weather["main"] as? String ?? ""
                            let icon = weather["icon"] as? String ?? ""
                            let temp = main["temp"] as? Double ?? 0.0
                            let tempMin = main["temp_min"] as? Double ?? 0.0
                            let tempMax = main["temp_max"] as? Double ?? 0.0
                            let humidity = main["humidity"] as? Int ?? 0
                            let windSpeed = wind["speed"] as? Double ?? 0.0
                            let windDeg = wind["deg"] as? Int ?? 0
                            
                            // ここを修正
                            let rainData = json["rain"] as? [String: Any]
                            let rain = rainData?["1h"] as? Double ?? 0.0
                            
                            let sunrise = sys["sunrise"] as? Int ?? 0
                            let sunset = sys["sunset"] as? Int ?? 0
                            
                            let weatherText = """
                            天気概要: \(mainWeather) (\(description))
                            気温: \(temp)°C
                            最低気温: \(tempMin)°C
                            最高気温: \(tempMax)°C
                            湿度: \(humidity)%
                            風速: \(windSpeed) m/s
                            風向: \(windDeg)°
                            日の出: \(Date(timeIntervalSince1970: TimeInterval(sunrise)))
                            日の入り: \(Date(timeIntervalSince1970: TimeInterval(sunset)))
                            """
                            
                            DispatchQueue.main.async {
                                self.weatherTextView.text = weatherText
                            }
                        }
                    } catch {
                        print("JSON解析エラー:", error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
    }
}

