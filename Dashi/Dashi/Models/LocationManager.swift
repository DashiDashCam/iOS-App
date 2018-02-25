//
//  locationManager.swift
//  Dashi
//
//  Created by Arslan Memon on 2/19/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import CoreLocation

//delegate has to handle the location updates
protocol locationHandlerDelegate {
    func handleUpdate(coordinate: CLLocationCoordinate2D)
}
class LocationManager: NSObject, CLLocationManagerDelegate
{
    
    var locationManager:CLLocationManager!
    var delegate: locationHandlerDelegate!
    
    override init(){
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
   
        
    }
    
    //start getting location updates
    func startLocUpdate() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    //stop getting updates
    func stopLocUpdate(){
        locationManager.stopUpdatingLocation()
    }
    
    //Do something with update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        // manager.stopUpdatingLocation()
       delegate.handleUpdate(coordinate: userLocation.coordinate)
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
}
}
