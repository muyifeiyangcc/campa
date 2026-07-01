//
//  BaseViewController.swift
//  Campa
//
//  Created by myfy on 2026/6/24.
//

import UIKit

enum NavBarType: String {
    case back = "back"
    case right = "right"
    case title = "title"
    case backTiltle = "backTiltle"
    case backRightBtn = "backRightBtn"
    case titleRightBtn = "titleRightBtn"
    case all = "all"
}
class BaseViewController: UIViewController {
    let navBar = UIView()
    
    lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "back"), for: .normal)
        btn.tag = 0
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var rightBtn: UIButton = {
        let btn = UIButton()
        btn.tag = 1
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var titleL: UILabel = { 
         let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 52/255.0, green: 4/255, blue: 4/255.0, alpha: 1.0)
        label.font = AppFont.semibold(size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var navType: NavBarType = .back {
        didSet {
            changeNavbar(navType)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        view.addSubview(navBar)
        navBar.backgroundColor = .clear
        view.bringSubviewToFront(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func changeNavbar(_ type: NavBarType) {
        switch type {
        case .back:
            navBar.addSubview(backBtn)
            NSLayoutConstraint.activate([
                backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                backBtn.widthAnchor.constraint(equalToConstant: 36),
                backBtn.heightAnchor.constraint(equalToConstant: 36)
            ])
        case .right:
            navBar.addSubview(rightBtn)
        case .title:
            navBar.addSubview(titleL)
            NSLayoutConstraint.activate([
                titleL.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                titleL.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                titleL.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -20),
            ])
        case .backTiltle:
            navBar.addSubview(backBtn)
            navBar.addSubview(titleL)
            NSLayoutConstraint.activate([
                backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                backBtn.widthAnchor.constraint(equalToConstant: 36),
                backBtn.heightAnchor.constraint(equalToConstant: 36)
            ])
            NSLayoutConstraint.activate([
                titleL.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                titleL.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 20),
                titleL.trailingAnchor.constraint(greaterThanOrEqualTo: navBar.trailingAnchor, constant: -20),
            ])
            
        case .backRightBtn:
            navBar.addSubview(backBtn)
            navBar.addSubview(rightBtn)
            NSLayoutConstraint.activate([
                backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                backBtn.widthAnchor.constraint(equalToConstant: 36),
                backBtn.heightAnchor.constraint(equalToConstant: 36)
            ])
        case .titleRightBtn:
            navBar.addSubview(rightBtn)
            navBar.addSubview(titleL)
            NSLayoutConstraint.activate([
                titleL.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                titleL.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                titleL.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -20),
            ])
        case .all:
            navBar.addSubview(backBtn)
            navBar.addSubview(titleL)
            navBar.addSubview(rightBtn)
            NSLayoutConstraint.activate([
                backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 20),
                backBtn.widthAnchor.constraint(equalToConstant: 36),
                backBtn.heightAnchor.constraint(equalToConstant: 36)
            ])
            NSLayoutConstraint.activate([
                titleL.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
                titleL.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                titleL.leadingAnchor.constraint(greaterThanOrEqualTo: backBtn.trailingAnchor, constant: 20),
                titleL.trailingAnchor.constraint(equalTo: rightBtn.leadingAnchor, constant: -20),
            ])
        }
    }
    
    func setTitleAndRight(title: String?, right: String?, rightSize: CGSize = .zero) {
        if let t = title {
            self.titleL.text = t
        }
        
        if let r = right {
            self.rightBtn.setImage(UIImage(named: r), for: .normal)
            NSLayoutConstraint.activate([
                rightBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                rightBtn.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -20),
                rightBtn.widthAnchor.constraint(equalToConstant: rightSize.width),
                rightBtn.heightAnchor.constraint(equalToConstant: rightSize.height)
            ])
        }
    }
    
    @objc func clickAction(_ sender: UIButton) {
        let idx = sender.tag
        if idx == 0 {
            self.backAction()
        } else {
            self.rightAction()
        }
        print(sender.tag)
    }
    
    func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func rightAction() {
        
    }
}
