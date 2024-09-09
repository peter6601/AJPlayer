//
//  AJPlayerControlView.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/23.
//

import UIKit
import SnapKit

public protocol AJPlayerControlViewDelegate: AnyObject {
    /// Call when tap play btn
    func playerControlView(_ controlView: AJPlayerControlView, isPlaying: Bool)
    /// Call when tap fullscreen btn
    func playerControlView(_ controlView: AJPlayerControlView, isFullScreen: Bool)
    /// Call when controlView show state changed
    func playerControlView(_ controlView: AJPlayerControlView, willAppear animated: Bool)
    func playerControlView(_ controlView: AJPlayerControlView, didAppear animated: Bool)
    func playerControlView(_ controlView: AJPlayerControlView, willDisappear animated: Bool)
    func playerControlView(_ controlView: AJPlayerControlView, didDisappear animated: Bool)
    /**
     call when slider action trigged
     
     - parameter controlView: control view
     - parameter slider: progress slider
     - parameter event:  action
     */
    func playerControlView(_ controlView: AJPlayerControlView, slider: UISlider, onSlider event: UIControl.Event)
}

open class AJPlayerControlView: UIView {
    open var playBtn: UIButton = UIButton(type: .custom)
    open var fullScreenBtn: UIButton = UIButton(type: .custom)
    open var timeProgressLabel: UILabel = UILabel()
    open var timeSlider: AJTimeSlider =  AJTimeSlider()
    open var progressView: UIProgressView = UIProgressView()
    
    open var mainMaskView: UIView = UIView()
    open var topMaskView: UIView = UIView()
    open var bottomMaskView: UIView = UIView()
    open var seekToView = UIView()
    open var seekToViewImage = UIImageView()
    open var seekToLabel = UILabel()
    open lazy var errorMsgLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    open var isShowing: Bool = false
    open var topMaskBarHeight: CGFloat = 37
    open var bottomMaskBarHeight: CGFloat = 40.0
    open var delayItem: DispatchWorkItem?
    
    private var mAlpha: CGFloat = 0.3
    private var oAlpha: CGFloat = 1.0
    private var animationTime: TimeInterval = 0.3

    // Notify
    open weak var delegate: AJPlayerControlViewDelegate?
    
    // MARK: - handle Slider Actions
    
    @objc open func progressSliderTouchBegan(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .touchDown)
    }
    @objc open func progressSliderValueChanged(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .valueChanged)
    }
    @objc open func progressSliderTouchEnded(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .touchUpInside)
    }
    
    
    open func controlViewAnimation(isShow: Bool, animated: Bool =  true) {
        if isShow {
            delegate?.playerControlView(self, willAppear: animated)
        } else {
            delegate?.playerControlView(self, willDisappear: animated)
        }
 
        if animated {
            animationView(isShow: isShow) { [weak self] in
                guard let self = self else { return }
                if isShow {
                    self.delegate?.playerControlView(self, didAppear: animated)
                } else {
                    self.delegate?.playerControlView(self, didDisappear: animated)
                }
            }
        } else {
            noAnimationView(isShow: isShow)
            if isShow {
                self.delegate?.playerControlView(self, didAppear: animated)
            } else {
                self.delegate?.playerControlView(self, didDisappear: animated)
            }
        }
    }
    
    private func animationView(isShow: Bool, completion: @escaping ()->()) {
        let mainAlpha =  isShow ? mAlpha : 0.0
        let otherAlpha = isShow ? oAlpha : 0.0
        UIView.animate(withDuration: animationTime) {[weak self] in
            self?.topMaskView.alpha = otherAlpha
            self?.bottomMaskView.alpha = otherAlpha
            
            self?.mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(mainAlpha)
            self?.layoutIfNeeded()
        } completion: { [weak self](isFinished) in
            guard let self = self else { return }
            if isFinished {
                self.isShowing = isShow
                completion()
               
            }
        }
    }
    
    private func noAnimationView(isShow: Bool) {
        let mainAlpha =  isShow ? mAlpha : 0.0
        let otherAlpha = isShow ? oAlpha : 0.0
        topMaskView.alpha = otherAlpha
        bottomMaskView.alpha = otherAlpha
        mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(mainAlpha)
        self.isShowing = isShow
        layoutIfNeeded()
    }
    
    func addViews() {
        addSubview(mainMaskView)
        mainMaskView.addSubview(topMaskView)
        mainMaskView.addSubview(bottomMaskView)
        
        bottomMaskView.addSubview(playBtn)
        bottomMaskView.addSubview(progressView)
        bottomMaskView.addSubview(timeSlider)
        bottomMaskView.addSubview(timeProgressLabel)
        bottomMaskView.addSubview(fullScreenBtn)
        
        addSubview(seekToView)
        seekToView.addSubview(seekToViewImage)
        seekToView.addSubview(seekToLabel)
        
        addSubview(errorMsgLabel)
    }
    func updateViewsConfig() {
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        seekToView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        seekToView.layer.cornerRadius = 4
        seekToView.clipsToBounds = true
        seekToView.isHidden = true
        seekToViewImage.image = AJPImageResource.get(.seek)
        
        seekToLabel.font = .systemFont(ofSize: 13)
        seekToLabel.adjustsFontSizeToFitWidth = true
        seekToLabel.textColor = UIColor(red: 0.9098, green: 0.9098, blue: 0.9098, alpha: 1.0)
        
        playBtn.setImage(AJPImageResource.get(.play), for: .normal)
        playBtn.setImage(AJPImageResource.get(.pause), for: .selected)
        timeProgressLabel.textColor = .white
        timeProgressLabel.font = UIFont(name: "PingFangSC-Medium", size: 10.0)
        timeProgressLabel.adjustsFontSizeToFitWidth = true
        timeProgressLabel.textAlignment = .center
        // Default text
        timeProgressLabel.text = "00:00"
        
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.value        = 0.0
        timeSlider.setThumbImage(AJPImageResource.get(.sliderThumb), for: .normal)
        timeSlider.maximumTrackTintColor = UIColor.clear
        timeSlider.minimumTrackTintColor = UIColor.red
        
        progressView.tintColor = UIColor.white.withAlphaComponent(0.6)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        
        fullScreenBtn.setImage(AJPImageResource.get(.fullScreen), for: .normal)
        fullScreenBtn.setImage(AJPImageResource.get(.endFullScreen), for: .selected)
    }
    
    func setViewActions() {
        timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchDragExit,
                                                                                          .touchCancel,
                                                                                          .touchUpInside])
    }
    
    func setViewConstraints() {
        mainMaskView.snp.makeConstraints { m in
            m.top.leading.bottom.trailing.equalToSuperview()
        }
        topMaskView.snp.makeConstraints { m in
            m.top.leading.trailing.equalToSuperview()
            m.height.equalTo(topMaskBarHeight)
        }
        bottomMaskView.snp.makeConstraints { m in
            m.leading.bottom.trailing.equalToSuperview()
            m.width.equalToSuperview()
            m.height.equalTo(bottomMaskBarHeight)
        }
        playBtn.snp.makeConstraints { m in
            m.leading.centerY.equalToSuperview()
            m.height.equalToSuperview().multipliedBy(0.8)
            m.width.equalTo(playBtn.snp.height)
        }
        timeSlider.snp.makeConstraints { m in
            m.centerY.equalToSuperview()
            m.leading.equalTo(playBtn.snp.trailing).offset(10)
            m.height.equalToSuperview().multipliedBy(0.9375)
        }
        progressView.snp.makeConstraints { m in
            m.bottom.leading.trailing.equalToSuperview()
            m.height.equalTo(3)
        }
        
    }
    
}

