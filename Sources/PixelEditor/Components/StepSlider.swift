//
// Copyright (c) 2018 Muukii <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import Foundation

import PixelEngine
import TransitionPatch

public final class StepSlider : UIControl {
  
  public enum Mode {
    case plus
    case plusAndMinus
    case minus
  }
  
  public var mode: Mode = .plusAndMinus {
    didSet {
      setupValues()
    }
  }

  public var isStepLabelHidden: Bool {
    get {
      return internalSlider.stepLabel.isHidden
    }
    set {
      internalSlider.stepLabel.isHidden = newValue
    }
  }
  
  public var title: String = "" {
    didSet {
      internalSlider.title = title
    }
  }

  public var minStep: Int = -100

  public var maxStep: Int = 100

  public override var intrinsicContentSize: CGSize {
    return internalSlider.intrinsicContentSize
  }

  private let feedbacker = UIImpactFeedbackGenerator(style: .light)
  private let feedbackGenerator = UISelectionFeedbackGenerator()

  private let offset: Double = 0.05

  public private(set) var step: Int = 0 {
    didSet {
      if oldValue != step {
        if step == 0, internalSlider.isTracking {
          feedbackGenerator.selectionChanged()
          feedbackGenerator.prepare()
        }
      }
      updateStepLabel()

      sendActions(for: .valueChanged)
    }
  }

  private let internalSlider = _StepSlider(frame: .zero)

  public override init(frame: CGRect) {
    super.init(frame: .zero)
    setup()
    feedbackGenerator.prepare()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
    feedbackGenerator.prepare()
  }

  private func setup() {

    internalSlider.addTarget(self, action: #selector(__didChangeValue), for: .valueChanged)
    internalSlider.title = title

    addSubview(internalSlider)
    internalSlider.frame = bounds
    internalSlider.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    setupValues()
  }

  private func setupValues() {
    
    switch mode {
    case .plus:
      maxStep = 100
      minStep = 0
    case .plusAndMinus:
      maxStep = 100
      minStep = -100
    case .minus:
      maxStep = 0
      minStep = -100
    }
    
    internalSlider.dotLocation = mode

    if minStep < 0 {
      internalSlider.minimumValue = -1
    } else {
      internalSlider.minimumValue = 0
    }

    if maxStep > 0 {
      internalSlider.maximumValue = 1
    } else {
      internalSlider.maximumValue = 0
    }

    step = 0
  }

  public func set(value: Double, min: Double, max: Double) {

    guard !internalSlider.isTracking else { return }

    if value == 0 {
      internalSlider.value = 0
    } else {
      if value > 0 {
        internalSlider.value = Float(
          ValuePatch(CGFloat(value))
            .progress(start: 0, end: CGFloat(max))
            .transition(start: CGFloat(offset), end: CGFloat(internalSlider.maximumValue))
            .value
        )
      } else {
        internalSlider.value = Float(
          ValuePatch(CGFloat(value))
            .progress(start: 0, end: CGFloat(min))
            .transition(start: CGFloat(-offset), end: CGFloat(internalSlider.minimumValue))
            .value
        )
      }
    }

    __didChangeValue()

  }

  public func transition(min: Double, max: Double) -> Double {

    if step == 0 {
      return 0
    } else {
      if step > 0 {
        return
          Double(
            ValuePatch(CGFloat(step))
              .progress(start: CGFloat(0), end: CGFloat(maxStep))
              .transition(start: 0, end: CGFloat(max))
              .value
        )
        
      } else {
        return
          Double(
            ValuePatch(CGFloat(step))
              .progress(start: CGFloat(0), end: CGFloat(minStep))
              .transition(start: 0, end: CGFloat(min))
              .value
        )
      }
    }
  }

  @objc
  private func __didChangeValue() {

    let value = internalSlider.value

    if case -offset ... offset = Double(value) {
      if self.step != 0 {
        self.step = 0
      }
      // To fix thumb
      internalSlider.value = 0
      return
    }

    let step: Int

    if value > 0 {

      step = Int(
        ValuePatch(CGFloat(value))
          .progress(start: CGFloat(offset), end: CGFloat(internalSlider.maximumValue))
          .transition(start: 0, end: CGFloat(maxStep))
          .value
          .rounded()
      )

    } else {

      step = Int(
        ValuePatch(CGFloat(value))
          .progress(start: CGFloat(-offset), end: CGFloat(internalSlider.minimumValue))
          .transition(start: 0, end: CGFloat(minStep))
          .value
          .rounded()
      )

    }

    self.step = Int(step)
  }

  private func updateStepLabel() {
    if step == 0 {
      internalSlider.stepLabel.text = "0"
      internalSlider.stepLabel.textColor = UIColor(white: 58.0 / 255.0, alpha: 1.0)
    } else if step > 0 {
      internalSlider.stepLabel.text = "+\(step)"
      internalSlider.stepLabel.textColor = UIColor.white
    } else {
      internalSlider.stepLabel.text = "\(step)"
      internalSlider.stepLabel.textColor = UIColor.white
    }
    internalSlider.updateStepLabel()
  }
}

extension StepSlider {

  public func set<T>(value: Double, in range: ParameterRange<Double, T>) {

    set(value: value, min: range.min, max: range.max)
  }

  public func transition<T>(in range: ParameterRange<Double, T>) -> Double {
    return transition(min: range.min, max: range.max)
  }
}

private final class _StepSlider: UISlider {

  var title: String! {
    didSet {
      self.titleLabel.text = title
      self.titleLabel.sizeToFit()
    }
  }
  
  let stepLabel: UILabel = .init()
  let titleLabel: UILabel = .init()

  private var _trackImageView: UIImageView?

  var dotLocation: StepSlider.Mode = .plus {
    didSet {
      setNeedsDisplay()
    }
  }

  override init(frame: CGRect) {

    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override func draw(_ rect: CGRect) {

    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }

    let scale = contentScaleFactor

    guard
      let layer = CGLayer(context, size: CGSize(width: bounds.size.width * scale, height: bounds.size.height * scale), auxiliaryInfo: nil),
      let layerContext = layer.context
      else {
        return
    }

    UIGraphicsPushContext(layerContext)

    layerContext.scaleBy(x: scale, y: scale)

    UIColor(white: 1, alpha: 1).setStroke()
    UIColor(white: 1, alpha: 1).setFill()

    line: do {
      let path = UIBezierPath()
      path.move(to: CGPoint.init(x: 10, y: bounds.midY))
      path.addLine(to: CGPoint.init(x: bounds.maxX - 10, y: bounds.midY))
      path.lineWidth = 4
      path.lineCapStyle = .round
      path.stroke()
    }

    /*
    dot: do {

      switch dotLocation {
      case .plus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: 10 - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      case .plusAndMinus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: bounds.midX - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      case .minus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: bounds.maxX - 10 - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      }

    }
    */

    UIGraphicsPopContext()

    context.setAlpha(0.2)
    context.draw(layer, in: bounds)
  }

  private func setup() {

    minimumTrackTintColor = UIColor.clear
    maximumTrackTintColor = UIColor.clear
    let image = UIImage(named: "slider_thumb_bordered", in: bundle, compatibleWith: nil)
    setThumbImage(image, for: [])

    let label = stepLabel
    label.backgroundColor = UIColor.clear
    label.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
    label.textColor = UIColor.white
    label.textAlignment = .right
    
    let title = titleLabel
    title.backgroundColor = UIColor.clear
    title.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    title.textColor = UIColor.white
    title.textAlignment = .left

    self.addSubview(label)
    self.addSubview(title)
    
    findTrackViewIfNeeded()

  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateStepLabel()
  }

  func updateStepLabel() {
    let width: CGFloat = 50.0
    let height: CGFloat = 30.0
    self.stepLabel.frame = CGRect(x: self.frame.width-width-10, y: -height, width: width, height: height)
    self.titleLabel.frame = CGRect(x: 10, y: -height, width: width, height: height)
    self.titleLabel.text = title
    self.titleLabel.sizeToFit()
  }

  private func findTrackViewIfNeeded() {

    guard _trackImageView == nil else {
      return
    }

    for imageView in self.subviews where imageView is UIImageView {

      if imageView.bounds.width == imageView.bounds.height {
        _trackImageView = imageView as? UIImageView
      }
    }
  }
}
