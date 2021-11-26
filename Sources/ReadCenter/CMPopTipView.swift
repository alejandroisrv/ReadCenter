import Foundation
import UIKit
import QuartzCore

@objc protocol CMPopTipViewDelegate : NSObjectProtocol {
    func popTipViewWasDismissedByUser(popTipView:CMPopTipView)
}

@objc enum CMPopTipPointDirection : Int {
    case `Any` = 0
    case Up
    case Down
}

@objc enum CMPopTipAnimation : NSInteger {
    case Slide = 0
    case Pop
}

@objc class CMPopTipView : UIView {
    
    weak var delegate:CMPopTipViewDelegate?
    
    var disableTapToDismiss = false
    var dismissTapAnywhere = false
    
    var borderColor = UIColor.black
    var bubbleBackgroundColor:UIColor = UIColor(red: 62.0/255.0, green: 60.0/255.0, blue:154.0/255.0, alpha:1.0)
    
    var title:String?
    var message:String?
    var customView:UIView?
    
    var titleColor:UIColor = UIColor.white
    var titleFont:UIFont = UIFont.boldSystemFont(ofSize: 16)
    var titleAlignment:NSTextAlignment = .center
    
    var textColor:UIColor = UIColor.white
    var textFont:UIFont = UIFont.boldSystemFont(ofSize: 14)
    var textAlignment:NSTextAlignment = .center
    
    lazy var titleAndMessageAttributedString:NSAttributedString = {
        
        var newString = ""
        var titleRange = NSMakeRange(0, 0)
        var messageRange = NSMakeRange(0, 0)
        if let title = self.title {
            newString = newString + title + "\n"
            titleRange = NSMakeRange(0, newString.count)//NSRangeFromString(title)
        }
        if let message = self.message {
            newString = newString + message
            messageRange = NSMakeRange(titleRange.length, message.count)
        }
        
        let attributedString = NSMutableAttributedString(string: newString)
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = self.titleAlignment
        titleParagraphStyle.lineBreakMode = NSLineBreakMode.byClipping
        
        let textParagraphStyle = NSMutableParagraphStyle()
        textParagraphStyle.alignment = self.textAlignment
        textParagraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: self.titleFont, range: titleRange)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: self.titleColor, range: titleRange)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: titleParagraphStyle, range: titleRange)
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: self.textFont, range: messageRange)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: self.textColor, range: messageRange)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: textParagraphStyle, range: messageRange)
        
        return attributedString
    }()
    
    var has3DStyle = true
    var hasShadow:Bool = true {
        didSet {
            if hasShadow {
                layer.shadowOffset = CGSize(width: 0, height: 3)
                layer.shadowRadius = 2
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOpacity = 0.3
            } else {
                layer.shadowOpacity = 0
            }
        }
    }
    var highlight = false
    var hasGradientBackground = true
    
    var animation:CMPopTipAnimation = .Slide
    var preferredPointDirection:CMPopTipPointDirection = .Any
    
    var cornerRadius:CGFloat = 10
    var maxWidth:CGFloat = 0
    
    var sidePadding:CGFloat = 2
    var topMargin:CGFloat = 2
    var pointerSize:CGFloat = 12
    var borderWidth:CGFloat = 1
    
    var targetObject:AnyObject?
    
    // MARK: Private properties
    private var autoDismissTimer:Timer?
    private var dismissTarget:UIButton?
    
    private var bubbleSize:CGSize = .zero
    private var pointDirection:CMPopTipPointDirection?
    private var targetPoint:CGPoint = .zero
    
    private var bubbleFrame:CGRect {
        var bFrame:CGRect!
        if (pointDirection == CMPopTipPointDirection.Up) {
            bFrame = CGRect(x: sidePadding, y: targetPoint.y+pointerSize, width: bubbleSize.width, height: bubbleSize.height);
        } else {
            bFrame = CGRect(x: sidePadding, y: targetPoint.y-pointerSize-bubbleSize.height, width: bubbleSize.width, height: bubbleSize.height);
        }
        return bFrame
    }
    
    private var contentFrame:CGRect {
        let cFrame = self.bubbleFrame.insetBy(dx: cornerRadius, dy: cornerRadius)
        return cFrame
    }
    
    // MARK: Init methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    convenience init(title titleToShow:String, message messageToShow:String) {
        self.init(frame: .zero)
        
        title = titleToShow
        message = messageToShow
        
        isAccessibilityElement = true
        accessibilityHint = messageToShow
    }
    
    convenience init(message messageToShow:String) {
        self.init(frame: .zero)
        
        message = messageToShow
        
        isAccessibilityElement = true
        accessibilityHint = messageToShow
    }
    
    convenience init(customView aView:UIView) {
        self.init(frame: .zero)
        
        customView = aView
        addSubview(customView!)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Drawing and layout methods
    
    override func layoutSubviews() {
        self.customView?.frame = contentFrame
    }
    
    override func draw(_ rect:CGRect) {
        
        let bubbleRect = self.bubbleFrame
        
        let c = UIGraphicsGetCurrentContext()
        
        c!.setStrokeColor(UIColor.black.cgColor)
        c!.setLineWidth(borderWidth)
        
        let bubblePath = CGMutablePath()
        
        let bubbleX = bubbleRect.origin.x; let bubbleY = bubbleRect.origin.y;
        let bubbleWidth = bubbleRect.size.width; let bubbleHeight = bubbleRect.size.height;
        
        var pointerSizePlusValue = pointerSize
        
        if pointDirection == .Down {
            // If the pointer is facing down, we need to minus pointerSize from targetPoint
            // to work out the coordinates of the pointer triangle
            pointerSizePlusValue = -pointerSizePlusValue
        }
        
        let targetPointA = CGPoint(x: targetPoint.x + sidePadding, y: targetPoint.y)
        let targetPointB = CGPoint(x: targetPoint.x + sidePadding + pointerSizePlusValue, y: targetPoint.y + pointerSizePlusValue)
        let targetPointC = CGPoint(x: targetPoint.x + sidePadding - pointerSizePlusValue, y: targetPoint.y + pointerSizePlusValue)
        
        // These two closures are used whening drawing the bubble rect
        let drawBubbleRectLeftHandSide = { () -> () in
            
            bubblePath.addArc(tangent1End: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY),
                              tangent2End: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY),
                              radius: self.cornerRadius)
            
            bubblePath.addArc(tangent1End: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY),
                              tangent2End: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY),
                              radius: self.cornerRadius)
            
        }
        
        let drawBubbleRectRightHandSide = { () -> () in
        
            
            bubblePath.addArc(tangent1End: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY),
                              tangent2End: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxX),
                              radius: self.cornerRadius)
            
            bubblePath.addArc(tangent1End: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY),
                              tangent2End: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY),
                              radius: self.cornerRadius)
        }
        
        // Bubble
        bubblePath.move(to: CGPoint(x: targetPointC.x, y: targetPointC.y))
        bubblePath.addLine(to: CGPoint(x: targetPointC.x, y: targetPointC.y))
        
        // Drawing in clockwise direction
        if pointDirection == .Up {
            drawBubbleRectRightHandSide()
            drawBubbleRectLeftHandSide()
        } else {
            drawBubbleRectLeftHandSide()
            drawBubbleRectRightHandSide()
        }
    
        bubblePath.addLine(to: CGPoint(x: targetPointC.x, y: targetPointC.y))
        
        bubblePath.closeSubpath()
        
        c!.saveGState()
        c!.addPath(bubblePath)
        c!.clip()
        
        if hasGradientBackground == false{
            // Fill with solid color
            c!.setFillColor(bubbleBackgroundColor.cgColor)
            c!.fill(bounds)
        } else {
            // Draw clipped background gradient
            let bubbleMiddle = (bubbleY + bubbleHeight * 0.5) / bounds.size.height
            
            let locationCount:size_t = 5
            let locationList:[CGFloat] = [0.0, bubbleMiddle-0.03, bubbleMiddle, bubbleMiddle+0.03, 1.0]
            
            let colorHL:CGFloat = highlight ? 0.25 : 0.0
            
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            var alpha:CGFloat = 0
            let numComponents = bubbleBackgroundColor.cgColor.numberOfComponents
            let components = bubbleBackgroundColor.cgColor.components
            
            if (numComponents == 2) {
                red = components![0]
                green = components![0]
                blue = components![0]
                alpha = components![1]
            } else {
                red = components![0]
                green = components![1]
                blue = components![2]
                alpha = components![3]
            }
            
            let colorList:[CGFloat] = [
                //red, green, blue, alpha
                red*1.16+colorHL, green*1.16+colorHL, blue*1.16+colorHL, alpha,
                red*1.16+colorHL, green*1.16+colorHL, blue*1.16+colorHL, alpha,
                red*1.08+colorHL, green*1.08+colorHL, blue*1.08+colorHL, alpha,
                red+colorHL, green+colorHL, blue+colorHL, alpha,
                red+colorHL, green+colorHL, blue+colorHL, alpha
            ]
            
            let myColorSpace = CGColorSpaceCreateDeviceRGB()
            let myGradient = CGGradient(colorSpace: myColorSpace, colorComponents: colorList, locations: locationList, count: locationCount)
            
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: 0, y: bounds.maxY)
            
            c!.drawLinearGradient(myGradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions())
        }
        
        // Draw top hightlight and bottom shadow
        if has3DStyle {
            c!.saveGState()
            let innerShadowPath = CGMutablePath()
            
            // Add a rectangle larger than the bounds of bubblePath
            innerShadowPath.addRect(bubblePath.boundingBox.insetBy(dx: -30, dy: -30))
            // Add bubblePath to innerShadow
            innerShadowPath.addPath(bubblePath)
            innerShadowPath.closeSubpath()
            
            // Draw top hightlight
            let hightlightColor = UIColor(white: 1.0, alpha: 0.75)
            c?.setFillColor(hightlightColor.cgColor)
            c?.setShadow(offset: CGSize(width: 0.0, height: 4.0), blur: 4.0, color: hightlightColor.cgColor)
            c?.addPath(innerShadowPath)
            c?.fillPath()
            
            
            // Draw bottom shadow
            let shadowColor = UIColor(white: 0.0, alpha: 0.4)
            c!.setFillColor(shadowColor.cgColor)
            c!.setShadow(offset: CGSize(width: 0.0, height: -4.0), blur: 4.0, color: shadowColor.cgColor)
            
            c?.addPath(innerShadowPath)
            c?.fillPath()
        }
        
    
        c?.restoreGState()
        
        // Draw Border
        if borderWidth > 0 {
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            var alpha:CGFloat = 0
            let numComponents = borderColor.cgColor.numberOfComponents
            let components = borderColor.cgColor.components
            
            if (numComponents == 2) {
                red = components![0]
                green = components![0]
                blue = components![0]
                alpha = components![1]
            } else {
                red = components![0]
                green = components![1]
                blue = components![2]
                alpha = components![3]
            }
            
            c?.setStrokeColor(red: red, green: green, blue: blue, alpha: alpha)
            c?.addPath(bubblePath)
            c?.drawPath(using: .stroke)
        }
        
        titleAndMessageAttributedString.draw(with: contentFrame, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
    }
    
    // MARK: Private - Size calculation methods
    private func titleAndMessageBoundingSize(width:CGFloat) -> CGSize {
        return titleAndMessageAttributedString.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil).size
    }
    
    // MARK: Presenting methods
    
    func presentPointingAtView(targetView:UIView, inView containerView:UIView, animated:Bool){
        
        if targetObject == nil {
            targetObject = targetView
        }
        
        // If we want to dismiss the bubble when the user taps anywhere, we need to insert
        // an invisible button over the background.
        if dismissTapAnywhere {
            dismissTarget = UIButton(type: .custom) as UIButton
            if let dismissTarget = dismissTarget {
                dismissTarget.addTarget(self, action: Selector("dismissTapAnywhereFired:"), for: UIControl.Event.touchUpInside)
                dismissTarget.setTitle("", for: UIControl.State.normal)
                dismissTarget.frame = containerView.bounds
                containerView.addSubview(dismissTarget)
            }
        }
        
        containerView.addSubview(self)
        
        // Size of rounded rect
        var rectWidth = CGFloat(0)
        let containerViewWidth = containerView.bounds.size.width
        let containerViewHeight = containerView.bounds.size.height
        let maxWidthLimit:CGFloat = containerViewWidth - cornerRadius * 2
        var widthProportion:CGFloat!
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            widthProportion = 1/3
        } else {
            widthProportion = 2/3
        }
        
        if maxWidth > 0 {
            // If "maxWidth" is specified, we need to check to make sure
            // that it's valid, i.e. less than "maxWidthLimit"
            rectWidth = min(maxWidth, maxWidthLimit)
        } else {
            rectWidth = floor(containerViewWidth * widthProportion)
        }
        
        var contentSize = CGSize.zero
        if let customView = customView {
            contentSize = customView.frame.size
        } else {
            contentSize = titleAndMessageBoundingSize(width: rectWidth)
        }
        
        bubbleSize = CGSize(width: contentSize.width + cornerRadius * 2, height: contentSize.height + cornerRadius * 2)
        
        var superview: UIView! = containerView.superview
        
        assert(superview != nil, "The container view does not have a superview")
        
        if superview is UIWindow {
            superview = containerView
        }
        
        assert(targetView.superview != nil, "The target view does not have a superview")
        let targetRelativeOrigin = targetView.superview!.convert(targetView.frame.origin, to: superview)
        let containerRelativeOrigin = superview.convert(containerView.frame.origin, to: superview)
        
        // Y coordinate of pointer target (within containerView)
        var pointerY = CGFloat(0)
        
        if targetRelativeOrigin.y + targetView.bounds.size.height < containerRelativeOrigin.y {
            
            pointDirection = .Up
        } else if targetRelativeOrigin.y > containerRelativeOrigin.y +  containerViewHeight {
            
            pointerY =  containerViewHeight
            pointDirection = .Down
            
        } else {
            
            pointDirection = preferredPointDirection
                
            let targetOriginInContainer = targetView.superview?.convert(CGRect.zero, to: containerView)
            
            let sizeBelow =  containerViewHeight - targetOriginInContainer!.minY
            
            if pointDirection == .Any {
                
                if sizeBelow > targetOriginInContainer!.minY {
                    pointDirection = .Up
                } else {
                    pointDirection = .Down
                }
                
            }
            
            if pointDirection == .Down {
                pointerY = targetOriginInContainer!.minY
            } else {
                pointerY = targetOriginInContainer!.minY + targetView.bounds.size.height
            }
        }
        
        let targetCenterInContainer = targetView.superview!.convert(targetView.center, to: containerView)
        var targetCenterX = targetCenterInContainer.x
        var finalOriginX = targetCenterX - round(bubbleSize.width * 0.5)
        
        // Making sure "finalOriginX" is within the limits
        finalOriginX = max( finalOriginX, sidePadding )
        finalOriginX = min( finalOriginX, containerViewWidth - bubbleSize.width - sidePadding )
        
        // Making sure "targetCenterX" is within the limits
        targetCenterX = max( targetCenterX, finalOriginX + cornerRadius + pointerSize )
        targetCenterX = min( targetCenterX, finalOriginX + bubbleSize.width - cornerRadius - pointerSize )
        
        let fullHeight = bubbleSize.height + pointerSize + 10
        var finalOriginY = CGFloat(0)
        
        if (pointDirection == .Up) {
            finalOriginY = topMargin + pointerY;
            targetPoint = CGPoint(x: targetCenterX-finalOriginX, y: 0);
        } else {
            finalOriginY = pointerY - fullHeight;
            targetPoint = CGPoint(x: targetCenterX-finalOriginX, y: fullHeight-2.0);
        }
        
        var finalFrame = CGRect(
            x: finalOriginX - sidePadding,
            y: finalOriginY,
            width: bubbleSize.width + sidePadding * 2,
            height: fullHeight
        )
        finalFrame = finalFrame.integral
        
        
        
        
        if animated {
            if animation == .Slide {
                
                var startFrame = finalFrame
                startFrame.origin.y += 10
                self.frame = startFrame
                self.alpha = 0
                
                setNeedsDisplay()
                
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    
                    self.alpha = 1.0
                    self.frame = finalFrame
                    
                    }) { (completed:Bool) -> Void in
                        
                }
                
            } else if animation == .Pop {
                
                // Start a little smaller
                self.frame = finalFrame
                self.alpha = 0.5
                self.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                setNeedsDisplay()
                
                // Animate to a bigger size
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    
                    self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self.alpha = 1.0
                    
                    }) { (completed:Bool) -> Void in
                        
                    UIView.animate(withDuration: 0.1, animations: { () -> Void in }, completion: { (completed:Bool) -> Void in
                                
                    })
                        
                }
                
            }
        } else {
            
            self.frame = finalFrame
            self.setNeedsDisplay()
        }
        
    }
    
    func presentPointingAtBarButtonItem(barButtonItem:UIBarButtonItem, animated:Bool){
        
        if let targetView = barButtonItem.value(forKey: "view") as? UIView {
            let targetSuperview = targetView.superview
            if let containerView = targetSuperview?.superview {
                targetObject = barButtonItem
                presentPointingAtView(targetView: targetView, inView: containerView, animated: animated)
            } else {
                print("Cannot determine container view from UIBarButtonItem: ", barButtonItem)
                targetObject = nil
                return
            }
        }
        
    }
    
    // MARK: Dismiss
    func dismissAnimated(animated:Bool) {
        if animated {
            var dismissFrame = frame
            dismissFrame.origin.y += 10.0
            
            UIView.animate(withDuration: 0.15, animations: { () -> Void in
                
                self.alpha = 0.0
                self.frame = dismissFrame
                
                }, completion: { (completed:Bool) -> Void in
                    
                    self.finalizeDismiss()
            })
            
        } else {
            finalizeDismiss()
        }
    }
    
    func autoDismissAnimated(animated:Bool, atTimeInterval timeInterval:TimeInterval) {
        let userInfo = ["animated" : NSNumber(value: animated)]
        
        autoDismissTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: Selector(("autoDismissAnimatedDidFire:")), userInfo: userInfo, repeats: false)
    }
    
    // MARK: Private: Dimiss
    private func finalizeDismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        
        dismissTarget?.removeFromSuperview()
        dismissTarget = nil
        
        removeFromSuperview()
        
        highlight = false
        targetObject = nil
    }
    
    private func dismissByUser() {
        highlight = true
        setNeedsDisplay()
        dismissAnimated(animated: true)
        notifyDelegatePopTipViewWasDismissedByUser()
    }
    
    private func notifyDelegatePopTipViewWasDismissedByUser() {
        delegate?.popTipViewWasDismissedByUser(popTipView: self)
    }
    
    // MARK: Dismiss selectors
    func dismissTapAnywhereFired(button:UIButton) {
        dismissByUser()
    }
    
    func autoDismissAnimatedDidFire(theTimer: Timer) {
       var shouldAnimate = false
        
        if let animated = theTimer.userInfo as? NSNumber {
           shouldAnimate = animated.boolValue
       }
        
        
        dismissAnimated(animated: shouldAnimate)
        notifyDelegatePopTipViewWasDismissedByUser()
    }
    
    // MARK: Handle touches
    // Swift 1.1: use "override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {"
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if disableTapToDismiss {
            super.touchesBegan(touches, with: event)
            return
        }
        
        dismissByUser()
    }
    
}
