//
//  City.swift
//  MapsPRactice
//
//  Created by Aswin Sasikanth Kanduri on 2023-01-22
//


import Foundation
import MapKit

class City: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
