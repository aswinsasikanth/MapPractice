//
//  ViewController.swift
//  MapsPRactice
//
//  Created by Aswin Sasikanth Kanduri on 2023-01-22
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var routeButton: UIButton!
    
    var routeLine: MKPolyline?
    var locationManager = CLLocationManager()
    var destinationCount = 0
    var destination: CLLocationCoordinate2D!
    var cities = [City]()
    var distanceLabels: [UILabel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeButton.isHidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.isZoomEnabled = false
        map.showsUserLocation = false
        map.delegate = self
        
        addDoubleTap()
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 1
        map.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        let touchpoint = sender.location(in: map)
        let coordinate = map.convert(touchpoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        
        destinationCount = map.annotations.count
        
        if destinationCount > 1 {
            routeButton.isHidden = false
        }
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: {(placemarks, error) in
            
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    if let placeMark = placemarks?[0] {
                        
                        if placeMark.locality != nil {
                            let place = City(title: placeMark.locality!, subtitle: "", coordinate: coordinate)
                            
                            // Add up to 3 Annotations on the map
                            if self.destinationCount <= 2 {
                                self.cities.append(place)
                                self.map.addAnnotation(place)
                            }
                            else {
                                for (index, myAnnotation) in self.map.annotations.enumerated() {
                                    
                                    if myAnnotation.title == placeMark.locality {
                                        print(index)
                                        self.removeOverlays()
                                        self.map.removeAnnotation(myAnnotation)
                                        self.cities.remove(at: index)
                                        self.cities.append(place)
                                        self.map.addAnnotation(place)
                                    }
                                }
                                self.destinationCount = self.map.annotations.count - 1
                            }

                            if self.destinationCount == 2 {
                                self.addPolyline()
                                self.addPolygon()
                            }
                        }
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        displayLocation(latitude: latitude, longitude: longitude)
    }
    
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees)
    {
        let latDelta: CLLocationDegrees = 0.7
        let lngDelta: CLLocationDegrees =  0.7
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        map.setRegion(region, animated: true)
    }
    
    private func showDistanceBetweenTwoPoint() {
        var nextIndex = 0
        
        for index in 0...2{
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }

            let distance: Double = getDistance(from: cities[index].coordinate, to:  cities[nextIndex].coordinate)
            
            let pointA: CGPoint = map.convert(cities[index].coordinate, toPointTo: map)
            let pointB: CGPoint = map.convert(cities[nextIndex].coordinate, toPointTo: map)
        
            let labelDistance = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 18))

            labelDistance.textAlignment = NSTextAlignment.center
            labelDistance.text = "\(String.init(format: "%2.f",  round(distance * 0.001)))km"
            labelDistance.textColor = .black
            labelDistance.font = UIFont(name: "Thonburi-Bold", size: 10.0)
            labelDistance.center = CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
            
            distanceLabels.append(labelDistance)
        }
        for label in distanceLabels {
            map.addSubview(label)
        }
    }
    
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        return from.distance(from: to)
    }
    
    func addPolyline() {
        let coordinates = cities.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline, level: .aboveRoads)
        
        showDistanceBetweenTwoPoint()
    }
    
    func addPolygon() {
        let coordinates = cities.map {$0.coordinate}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polygon)
    }
    
    @IBAction func drawRoute(_ sender: Any) {
        map.removeOverlays(map.overlays)
        removeDistanceLabel()
        
        var nextIndex = 0
        for index in 0...2 {
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }
            
            let sourcePlaceMark = MKPlacemark(coordinate: cities[index].coordinate)
            let destinationPlaceMark = MKPlacemark(coordinate: cities[nextIndex].coordinate)
            let directionRequest = MKDirections.Request()
            
            directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
            directionRequest.transportType = .automobile
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResponse = response else {return}
                
                let route = directionResponse.routes[0]
                
                self.routeLine = route.polyline
                self.map.addOverlay(self.routeLine!, level: .aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            }
        }
    }
    
    private func removeDistanceLabel() {
        for label in distanceLabels {
            label.removeFromSuperview()
        }
        
        distanceLabels = []
    }
    
    func removePin() {
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
    }
    
    func removeOverlays() {
        routeButton.isHidden = true
        removeDistanceLabel()
        
        for polygon in map.overlays {
            map.removeOverlay(polygon)
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 3
            
            if routeLine != nil {
                rendrer.strokeColor = UIColor.systemBlue
                rendrer.lineWidth = 5
            }
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

