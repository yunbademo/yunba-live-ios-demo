//
//  Model.swift
//  YunbaLiveDemo
//
//  Created by Frain on 16/10/31.
//  Copyright © 2016年 com.yunba. All rights reserved.
//

import Foundation
import FxJSON

enum Topic {
  
  static let bullet = "bullet"
  static let like = "like"
  static let stat = "stat"
}

struct Bullet: JSONDecodable, JSONEncodable {
  
  let color: UIColor
  let dur: Int
  let text: String
  let mode: Mode
  
  enum Mode: Int, JSONTransformable {
    case upScroll = 1
    case downScroll = 2
    case downStatic = 4
    case upStatic = 5
    case reverse = 6
  }
  
  init(decode json: JSON) throws {
    color = try json["color"]<
    dur   = try json["dur"]<
    text  = try json["text"]<
    mode  = try json["mode"]<
  }
  
  init(color: UIColor = .white, dur: Int = 4000,
       text: String, mode: Mode = .upScroll) {
    self.color = color
    self.dur = dur
    self.text = text
    self.mode = mode
  }
}
struct Stat: JSONDecodable {
  let like: Int
  let online: Int
  
  init(decode json: JSON) throws {
    like   = try json["like"]<
    online = try json["presence"]<
  }
}

extension UIColor: JSONConvertable, JSONSerializable {
  
  public static func convert(from json: JSON) -> Self? {
    guard let hex = Int(json) else { return nil }
    let r = (CGFloat)((hex >> 16) & 0xFF)
    let g = (CGFloat)((hex >> 8) & 0xFF)
    let b = (CGFloat)(hex & 0xFF)
    return self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
  }
  
  public var json: JSON {
    var (red, green, blue, alpha) = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
    if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      return JSON(Int(red * 255) * 2 << 16 + Int(green * 255) * 2 << 8 + Int(blue * 255))
    }
    return JSON()
  }
}
