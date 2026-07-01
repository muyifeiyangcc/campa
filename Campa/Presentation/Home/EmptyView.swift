//
//  EmptyView.swift
//  Campa
//
//  Created by myfy on 2026/6/25.
//

import SnapKit
import UIKit

class EmptyView: UIView {
    private var kTitleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    private var kTitleColor = UIColor(red: 0.28, green: 0.20, blue: 0.16, alpha: 1.0)

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "nocontent")
        return view
    }()

    private lazy var titleLbl: UILabel = {
        let lbl = UILabel()
        lbl.font = kTitleFont
        lbl.textColor = kTitleColor
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubViews()
    }

    private func setupSubViews() {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }
        addSubview(titleLbl)
        titleLbl.text = "There is currently no content here."
        titleLbl.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.left.equalTo(86)
            make.right.equalTo(-86)
        }
    }
}
