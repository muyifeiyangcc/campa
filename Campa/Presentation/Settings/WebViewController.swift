//
//  WebViewController.swift
//  Campa
//
//  Created by myfy on 2026/6/25.
//

import UIKit
import WebKit

enum LinkType: String {
     case userAgreement = "https://app.9f4v7tml.link/users"
     case privacyPolicy = "https://app.9f4v7tml.link/privacy"
}

class WebViewController: BaseViewController {

    private lazy var webView: WKWebView = {
        let view = WKWebView()
        return view
    }()

    var type: LinkType = .userAgreement
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navType = .back
        
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        if let u = URL(string: self.type.rawValue) {
            webView.load(URLRequest(url: u))
        }
    }
}
