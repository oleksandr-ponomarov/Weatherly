//   
//  MainInteractor.swift
//  Weatherly
//
//  Created by Aleksandr on 21.07.2022.
//

import CoreLocation
import Realm
import RealmSwift

protocol MainInteractorType {
    var selectedLocation: Location? { get }
    var current: Current? { get }
    var hours: [Hourly] { get }
    var days: [Daily] { get }
    
    func updateWeatherData(completion: @escaping(Responce<Bool>) -> Void)
    func save(location: Location)
    func subscribeLocationNotification(completion: @escaping(RealmCollectionChange<Results<Location>>) -> Void)
}

class MainInteractor: MainInteractorType {
    
    private let weatherService = WeatherService()
    private let realmManager = RealmManager.shared
    private var notificationToken: NotificationToken?
    
    // MARK: - Protocol property
    var selectedLocation: Location? {
        return realmManager.getObject(primaryKey: RealmKeyConstants.locationId)
    }
    
    var current: Current? {
        hourlyEntity?.current
    }
    
    var hours: [Hourly] {
        guard let hoursList = hourlyEntity?.hourly else { return [] }
        
        let hours = Array(hoursList)
        let hoursInDay = 24
        return hours.count >= hoursInDay ? Array(hours[0..<hoursInDay]) : hours
    }
    
    var days: [Daily] {
        guard let daysList = hourlyEntity?.daily else { return [] }
        
        return Array(daysList)
    }
    
    private var hourlyEntity: HourlyEntity? {
        return realmManager.getObject(primaryKey: RealmKeyConstants.hourlyEntityId)
    }
    
    // MARK: - Protocol methods
    func updateWeatherData(completion: @escaping(Responce<Bool>) -> Void) {
        guard let latitude = selectedLocation?.latitude,
              let longitude = selectedLocation?.longitude else { return }
        
        weatherService.getHourly(lat: String(latitude), lon: String(longitude)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let hourlyEntity):
                self.realmManager.addOrUpdate(object: hourlyEntity)
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func save(location: Location) {
        realmManager.addOrUpdate(object: location)
    }
    
    func subscribeLocationNotification(completion: @escaping(RealmCollectionChange<Results<Location>>) -> Void) {
        notificationToken = realmManager.observeUpdateChanges(type: Location.self, completion)
    }
}
