//
//  IRFontSettingView.swift
//  iRead
//
//  Created by zzyong on 2020/10/14.
//  Copyright © 2020 zzyong. All rights reserved.
//

import UIKit

protocol IRFontSettingViewDelegate: AnyObject {
    
    func fontSettingView(_ view: IRFontSettingView, didChangeTextSizeMultiplier textSizeMultiplier: Int)
    func fontSettingViewDidClickFontSelect(_ view: IRFontSettingView)
}

class IRFontSettingView: UIView, IRArrowSettingViewDelegate {
    
    let multiplierSacle: Int = 2
    static let bottomSapcing: CGFloat = 5
    static let viewHeight: CGFloat = IRArrowSettingView.viewHeight + 40
    static let totalHeight = bottomSapcing + viewHeight
    
    weak var delegate: IRFontSettingViewDelegate?
    
    var fontTypeSelectView = IRArrowSettingView()
    lazy var bottomLine = UIView()
    lazy var midLine = UIView()
    var increaseBtn = UIButton.init(type: .custom)
    var reduceBtn = UIButton.init(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupSubviews()
    }
    
    @objc func didIncreaseBtnClick() {
        reduceBtn.isEnabled = true
        let endValue = IRReaderConfig.textSizeMultiplier + multiplierSacle
        IRReaderConfig.textSizeMultiplier = min(endValue, IRReaderConfig.maxTextSizeMultiplier)
        increaseBtn.isEnabled = IRReaderConfig.textSizeMultiplier < IRReaderConfig.maxTextSizeMultiplier
        self.delegate?.fontSettingView(self, didChangeTextSizeMultiplier: IRReaderConfig.textSizeMultiplier)
    }
    
    @objc func didReduceBtnClick() {
        increaseBtn.isEnabled = true
        let endValue = IRReaderConfig.textSizeMultiplier - multiplierSacle
        IRReaderConfig.textSizeMultiplier = max(endValue, IRReaderConfig.minTextSizeMultiplier)
        reduceBtn.isEnabled = IRReaderConfig.textSizeMultiplier > IRReaderConfig.minTextSizeMultiplier
        self.delegate?.fontSettingView(self, didChangeTextSizeMultiplier: IRReaderConfig.textSizeMultiplier)
    }
    
    func setupSubviews() {
        
        fontTypeSelectView.titleLabel.text = "Fuente"
        fontTypeSelectView.detailText = IRReaderConfig.fontDispalyName
        fontTypeSelectView.delegate = self
        self.addSubview(fontTypeSelectView)
        fontTypeSelectView.snp.makeConstraints { (make) in
            make.bottom.right.left.equalTo(self)
            make.height.equalTo(IRArrowSettingView.viewHeight)
        }
        
        self.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) -> Void in
            make.right.left.equalTo(self)
            make.height.equalTo(1)
            make.bottom.equalTo(fontTypeSelectView.snp.top)
        }
        
        increaseBtn.setTitle("A", for: .normal)
        increaseBtn.isEnabled = IRReaderConfig.textSizeMultiplier < IRReaderConfig.maxTextSizeMultiplier
        increaseBtn.addTarget(self, action: #selector(didIncreaseBtnClick), for: .touchUpInside)
        increaseBtn.contentHorizontalAlignment = .center
        increaseBtn.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        self.addSubview(increaseBtn)
        increaseBtn.snp.makeConstraints { (make) -> Void in
            make.right.top.equalTo(self)
            make.bottom.equalTo(fontTypeSelectView.snp.top)
            make.left.equalTo(self.snp.centerX)
        }
    
        self.addSubview(midLine)
        midLine.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self)
            make.height.top.equalTo(increaseBtn)
            make.width.equalTo(1)
        }
        
        reduceBtn.setTitle("A", for: .normal)
        reduceBtn.isEnabled = IRReaderConfig.textSizeMultiplier > IRReaderConfig.minTextSizeMultiplier
        reduceBtn.addTarget(self, action: #selector(didReduceBtnClick), for: .touchUpInside)
        reduceBtn.contentHorizontalAlignment = .center
        reduceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        self.addSubview(reduceBtn)
        reduceBtn.snp.makeConstraints { (make) -> Void in
            make.left.top.equalTo(self)
            make.bottom.equalTo(increaseBtn)
            make.right.equalTo(self.snp.centerX)
        }
    }
    
    func updateThemeColor() {
        
        self.backgroundColor = IRReaderConfig.bgColor
        midLine.backgroundColor = IRReaderConfig.separatorColor
        bottomLine.backgroundColor = IRReaderConfig.separatorColor
        fontTypeSelectView.titleLabel.textColor = IRReaderConfig.textColor
        
        increaseBtn.setTitleColor(IRReaderConfig.textColor, for: .normal)
        increaseBtn.setTitleColor(IRReaderConfig.textColor.withAlphaComponent(0.3), for: .highlighted)
        increaseBtn.setTitleColor(IRReaderConfig.textColor.withAlphaComponent(0.3), for: .disabled)
        
        reduceBtn.setTitleColor(IRReaderConfig.textColor, for: .normal)
        reduceBtn.setTitleColor(IRReaderConfig.textColor.withAlphaComponent(0.3), for: .highlighted)
        reduceBtn.setTitleColor(IRReaderConfig.textColor.withAlphaComponent(0.3), for: .disabled)
    }
    
    // MARK: - IRArrowSettingViewDelegate
    func didClickArrowSettingView(_ view: IRArrowSettingView) {
        self.delegate?.fontSettingViewDidClickFontSelect(self)
    }
}
