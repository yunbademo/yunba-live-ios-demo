//
//  AppDelegate.swift
//  YunbaLiveDemo
//
//  Created by Frain on 16/10/27.
//  Copyright © 2016年 com.yunba. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    YunBaService.setup(withAppkey: "56a0a88c4407a3cd028ac2fe")
    
    return true
  }
}

