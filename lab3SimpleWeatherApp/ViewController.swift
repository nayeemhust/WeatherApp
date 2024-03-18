//  ViewController.swift
//  lab3SimpleWeatherApp
//  Created by Nazmul Alam Nayeem on 2024-03-12.

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherCondition: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var localTimeLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    
    let locationManager = CLLocationManager()
    var currentCity:String=""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ImageDemo()
        searchTextField.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

    }
    private func ImageDemo() {
        let configuration = UIImage.SymbolConfiguration(paletteColors: [
            .systemRed, .systemTeal, .systemOrange
        ])
        
        weatherCondition.preferredSymbolConfiguration = configuration
        weatherCondition.image = UIImage(systemName: "moon.fill")
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManager.startUpdatingLocation()

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                locationManager.stopUpdatingLocation()
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                loadWeather(search: "\(lat),\(lon)", isCelsius: true)
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Failed to find user's location: \(error.localizedDescription)")
        }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text, isCelsius: tempSwitch.isOn)
        searchTextField.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print(searchTextField.text ?? "")
        searchTextField.endEditing(true)
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text != "" { return true }
        
        textField.placeholder = "Please type the city name"
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        loadWeather(search: textField.text, isCelsius: tempSwitch.isOn)
        searchTextField.text = ""
    }
    
    
    @IBAction func switchController(_ sender: UISwitch) {
        
        loadWeather(search: currentCity,isCelsius: tempSwitch.isOn)

    }

    
    private func loadWeather(search: String?, isCelsius: Bool) {
            guard let search = search, let url = getURL(query: search) else { return }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self, let data = data, error == nil else { return }
                
                if let weatherResponse = self.parseJson(data: data) {
                    DispatchQueue.main.async {
                        self.locationLabel.text = weatherResponse.location.name
                        self.temperatureLabel.text = isCelsius ? "\(weatherResponse.current.temp_f)°F" : "\(weatherResponse.current.temp_c)°C"
                        self.conditionLabel.text = weatherResponse.current.condition.text
                        self.weatherCondition.image = self.getWeatherSymbol(conditionText: weatherResponse.current.condition.text, isDay: weatherResponse.current.is_day != 0)
                        self.localTimeLabel.text = weatherResponse.location.localtime
                    }
                }
            }.resume()
            currentCity = search
        }
    
    private func getWeatherSymbol(conditionText: String, isDay: Bool) -> UIImage? {
        let lowercasedCondition = conditionText.lowercased()

        let weatherSymbols: [String: String] = [
            "sunny": isDay ? "sun.max.fill" : "moon.fill",
            "partly cloudy": isDay ? "cloud.sun.fill" : "cloud.moon.fill",
            "cloudy": isDay ? "cloud.fill" : "cloud.moon.fill",
            "overcast": isDay ? "smoke.fill" : "cloud.moon.fill",
            "clear": isDay ? "sun.max.fill" : "moon.stars.fill",
            "mist": "cloud.fog.fill",
            "patchy rain possible": "cloud.drizzle.fill",
            "patchy snow possible": "cloud.snow.fill",
            "patchy sleet possible": "cloud.sleet.fill",
            "patchy freezing drizzle possible": "cloud.hail.fill",
            "fog": "cloud.fog.fill",
            "freezing fog": "cloud.fog.fill",
            "patchy light drizzle": "cloud.drizzle.fill",
            "light drizzle": "cloud.drizzle.fill",
            "freezing drizzle": "cloud.hail.fill",
            "heavy freezing drizzle": "cloud.hail.fill",
            "patchy light rain": "cloud.drizzle.fill",
            "light rain": "cloud.drizzle.fill",
            "moderate rain at times": "cloud.rain.fill",
            "moderate rain": "cloud.rain.fill",
            "heavy rain at times": "cloud.heavyrain.fill",
            "heavy rain": "cloud.heavyrain.fill",
            "light freezing rain": "cloud.sleet.fill",
            "moderate or heavy freezing rain": "cloud.sleet.fill",
            "patchy light snow": "cloud.snow.fill",
            "light snow": "cloud.snow.fill",
            "patchy moderate snow": "cloud.snow.fill",
            "moderate snow": "cloud.snow.fill",
            "patchy heavy snow": "cloud.snow.fill",
            "heavy snow": "cloud.snow.fill",
            "ice pellets": "cloud.sleet.fill",
            "light rain shower": "cloud.drizzle.fill",
            "moderate or heavy rain shower": "cloud.rain.fill",
            "torrential rain shower": "cloud.heavyrain.fill",
            "light sleet showers": "cloud.sleet.fill",
            "moderate or heavy sleet showers": "cloud.sleet.fill",
            "light snow showers": "cloud.snow.fill",
            "moderate or heavy snow showers": "cloud.snow.fill",
            "light showers of ice pellets": "cloud.sleet.fill",
            "moderate or heavy showers of ice pellets": "cloud.sleet.fill",
            "patchy light rain with thunder": "cloud.bolt.rain.fill",
            "moderate or heavy rain with thunder": "cloud.bolt.rain.fill",
            "patchy light snow with thunder": "cloud.bolt.snow.fill",
            "moderate or heavy snow with thunder": "cloud.bolt.snow.fill",
        ]
        guard let img = weatherSymbols[lowercasedCondition] else {
            return nil
        }
        return UIImage(systemName: img)
    }
    
    
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "d0ea15866c9448d492c221111241203"
        let urlString = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = urlString.flatMap { URL(string: $0) }
//        print(url ?? "")
        return url
    }


    private func parseJson(data: Data) -> Weather? {
        let decoder = JSONDecoder()
        let weather = try? decoder.decode(Weather.self, from: data)
        
        if weather == nil {
//            print("Decoding error")
        }
            return weather
    }
}

struct Weather: Decodable {
    let location: Location
    let current: CurrentWeather
}

struct Location: Decodable {
    let name: String
    let localtime: String
}

struct CurrentWeather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day: Int
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
}
