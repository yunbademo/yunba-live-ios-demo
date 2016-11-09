//
//  ViewController.swift
//  YunbaLiveDemo
//
//  Created by Frain on 16/10/27.
//  Copyright © 2016年 com.yunba. All rights reserved.
//

import UIKit
import SnapKit
import IJKMediaFramework

class LiveViewController: UIViewController {
  
  var player: IJKFFMoviePlayerController!
  var renderer = BarrageRenderer()
  
  @IBOutlet weak var playerView: UIView!
  @IBOutlet weak var maskView: UIView!
  @IBOutlet weak var buttonView: UIView!
  
  @IBOutlet weak var chatTable: UITableView!
  
  @IBOutlet weak var onlineLabel: UILabel!
  @IBOutlet weak var likeLabel: UILabel!
  
  @IBOutlet weak var pauseBtm: UIButton!
  
  @IBOutlet weak var likeButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var textField: UITextField!
  
  @IBOutlet weak var bottom: NSLayoutConstraint!
  
  var like: Int = 0 { didSet { likeLabel.text = "赞 \(like)" } }
  var online: Int = 0 { didSet { onlineLabel.text = "在线 \(online)" } }
  var maskViewIsAppear: Bool = true
  
  var messages = [String]()

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpYunbaService()
    setUpPlayer()
    setUpKeyBoardNotification()
    
    chatTable.estimatedRowHeight = 22
    chatTable.rowHeight = UITableViewAutomaticDimension
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    player.prepareToPlay()
    renderer.start()
  }
  
  func setUpYunbaService() {
    YunBaService.subscribe(Topic.bullet, resultBlock: nil)
    YunBaService.subscribe(Topic.like, resultBlock: nil)
    YunBaService.subscribe(Topic.stat, resultBlock: nil)
    YunBaService.setAlias("\(arc4random())", resultBlock: nil)
    
    NotificationCenter.default.addObserver(
      self, selector: #selector(LiveViewController.onMessageReceived(notification:)),
      name: NSNotification.Name.ybDidReceiveMessage, object: nil
    )
  }
  
  func setUpPlayer() {
    let options = IJKFFOptions.byDefault()
    let url = URL(string: "rtmp://live.lettuceroot.com/yunba/live-demo")
    
    player = IJKFFMoviePlayerController(contentURL: url, with: options)
    
    let autoresize = UIViewAutoresizing.flexibleWidth.rawValue |
      UIViewAutoresizing.flexibleHeight.rawValue
    
    player.view.autoresizingMask = UIViewAutoresizing(rawValue: autoresize)
    
    player.scalingMode = .aspectFit
    player.shouldAutoplay = true
    
    view.autoresizesSubviews = true
    playerView.addSubview(player.view)
    playerView.addSubview(renderer.view)
    
    player.view.snp.makeConstraints { $0.edges.equalTo(playerView) }
    renderer.view.snp.makeConstraints { $0.edges.equalTo(playerView) }
  }
  
  @IBAction func sendMessage(_ sender: AnyObject) {
    if let text = textField.text, text != "" {
      let data = try! Bullet(text: text).jsonData()
      YunBaService.publish(Topic.bullet, data: data, resultBlock: nil)
      textField.text = ""
    }
  }
  
  @IBAction func like(_ sender: AnyObject) {
    YunBaService.publish(Topic.like, data: try? [].jsonData(), resultBlock: nil)
  }
  
  @IBAction func onTableTap(_ sender: AnyObject) {
    textField.resignFirstResponder()
  }
  
  @IBAction func onMaskviewTap(_ sender: AnyObject) {
    maskViewIsAppear ? maskViewDisappear() : maskViewAppear()
  }
  
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  @objc func onMessageReceived(notification: Notification) {
    if let message = notification.object as? YBMessage {
      switch message.topic {
      case Topic.bullet: (try? Bullet(jsonData: message.data)).map(sendBullet)
      case Topic.stat: (try? Stat(jsonData: message.data)).map(setStat)
      case Topic.like: like += 1
      default: break
      }
    }
    if let messages = notification.object as? YBPresenceEvent {
      print(messages.alias)
    }
  }
  
  func sendBullet(_ bullet: Bullet) {
    
    let descriptor = BarrageDescriptor()
    descriptor.spriteName = NSStringFromClass(BarrageWalkTextSprite.self)
    descriptor.params["text"] = bullet.text
    descriptor.params["textColor"] = bullet.color
    descriptor.params["speed"] = Double(view.frame.width)/(Double(bullet.dur)/1000)
    descriptor.params["side"] = BarrageWalkSide.default.rawValue
    descriptor.params["direction"] = BarrageWalkDirection.R2L.rawValue
    renderer.receive(descriptor)
    
    messages.append(bullet.text)
    chatTable.reloadData()
    chatTable.scrollToRow(at: IndexPath(row: messages.count + 1, section: 0),
                          at: .top, animated: true)
  }
  
  func setStat(_ stat: Stat) {
    like = stat.like
    online = stat.online
  }
}

extension LiveViewController {
  
  func maskViewDisappear() {
    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
      self.pauseBtm.alpha = 0
      self.pauseBtm.isUserInteractionEnabled = false
      UIApplication.shared.setStatusBarHidden(true, with: .fade)
      }, completion: { _ in })
    maskViewIsAppear = false
  }
  
  func maskViewAppear() {
    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
      self.pauseBtm.alpha = 1
      self.pauseBtm.isUserInteractionEnabled = true
      UIApplication.shared.setStatusBarHidden(false, with: .fade)
      }, completion: { _ in })
    maskViewIsAppear = true
  }
  
  func setUpKeyBoardNotification() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(LiveViewController.keyboardWillShow(notification:)),
      name: NSNotification.Name.UIKeyboardWillShow, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(LiveViewController.keyboardWillHide(notification:)),
      name: NSNotification.Name.UIKeyboardWillHide, object: nil
    )
  }
  
  @objc func keyboardWillShow(notification: Notification) {
    let value = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
    let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
    UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
      self.bottom.constant = value.cgRectValue.size.height
      }, completion: { _ in })
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
  
  @objc func keyboardWillHide(notification: Notification) {
    let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
    UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
      self.bottom.constant = 0
      }, completion: { _ in })
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
}

//MARK: - TableView

extension LiveViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "message") as! MessageCell
    switch indexPath.row {
    case messages.count...(messages.count + 2):
      cell.messageLabel.text = " "
    default:
      cell.messageLabel.text = messages[indexPath.row]
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count + 2
  }
}
