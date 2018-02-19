//
//  locationManager.swift
//  Dashi
//
//  Created by Arslan Memon on 2/19/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import CoreLocation
class LocationManager: NSObject, CLLocationManagerDelegate
{
    
    var locationManager:CLLocationManager!
    
 
    override init(){
        locationManager = CLLocationManager()
   
    }
    func determineMyCurrentLocation() {
        locationManager.delegate=self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        // manager.stopUpdatingLocation()
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
}
}
