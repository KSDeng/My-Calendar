//
//  MapViewController.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/2.
//  Copyright © 2019 dks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


// References:
// https://medium.com/@pravinbendre772/search-for-places-and-display-results-using-mapkit-a987bd6504df
// https://www.youtube.com/watch?v=GYzNsVFyDrU          // search for places in map kit


// MARK: TODOs
// 使用当前位置时产生比较友好的信息

protocol SetLocationHandle {
    func setLocation(location: MKPlacemark)
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    // 位置管理器
    let locationManager = CLLocationManager()
    
    // 经度和纬度方向的初始显示范围(单位:米)
    // let regionRadius: CLLocationDistance = 5000
    
    // 搜索控制器
    var searchController: UISearchController? = nil
    // 用户位置
    var userLoction: CLLocationCoordinate2D?
    // 选择的位置
    var locationSelected: MKPlacemark?
    
    var delegate:SetLocationHandle?
    
    // 加载搜索结果的展示页面
    let locationResultTable = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LocationSearchResultView") as! LocationSearchResultViewController
    
    override func viewWillAppear(_ animated: Bool) {
        mapView.delegate = self
        
        // 设置并请求当前位置
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()     // 请求运行时的位置信息使用权
        
        locationResultTable.delegate = self
        locationResultTable.userLoction = userLoction
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSearchBar()
        
        setupConfirmButton()
        
        navigationItem.title = "选择地点"
    }
    
    private func setupConfirmButton(){
        let confirmButton = UIBarButtonItem(title: "确定", style: .plain, target: self, action: #selector(confirmButtonClicked))
        navigationItem.rightBarButtonItem = confirmButton
    }
    
    @objc func confirmButtonClicked(){
        if let loc = locationSelected {
            delegate?.setLocation(location: loc)
        }else{
            print("No location selected error!")
        }
        navigationController?.popViewController(animated: true)
    }
    
    // 配置搜索栏
    private func setupSearchBar(){
        searchController = UISearchController(searchResultsController: locationResultTable)
        searchController?.searchResultsUpdater = locationResultTable
        
        // 将搜索框嵌入导航栏
        let searchBar = searchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "搜索地点"
        
        navigationItem.searchController = searchController
        
        searchController?.hidesNavigationBarDuringPresentation = true
        searchController?.obscuresBackgroundDuringPresentation = true
        //searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    // 将地图聚焦到某个范围，参数为位置坐标、纬度范围、经度范围
    func centerMapOnLocation(location: CLLocationCoordinate2D, latSpan: Double, longSpan: Double) {
        /*
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        */
        let span = MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: longSpan)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 获得允许之后请求当前位置
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    // 处理请求位置的结果
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLoction = location.coordinate
            centerMapOnLocation(location: location.coordinate, latSpan: 0.1, longSpan: 0.1)
        }
    }
    
    // 请求位置发生错误时调用(必须实现否则会发生SIGABRT异常)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
}

extension MapViewController: HandleLocationSelect {
    func dropPinZoomIn(placemark: MKPlacemark) {
        locationSelected = placemark
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.title = placemark.name
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
        centerMapOnLocation(location: placemark.coordinate, latSpan: 0.1, longSpan: 0.1)
        navigationItem.title = placemark.name
    }
    
}
