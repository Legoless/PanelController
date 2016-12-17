//
//  PanelController.swift
//  PanelController
//
//  Created by Dal Rupnik on 18/10/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import UIKit

public extension UIViewController {
    public var panelController: PanelController? {
        return self.parent as? PanelController
    }
}

public protocol PanelControllerDelegate : class {
    func panelController(panelController: PanelController, willTransitionTo side: PanelController.Side)
    func panelController(panelController: PanelController, didTransitionTo side: PanelController.Side)
 }

public class PanelController: UIViewController {
    
    // MARK: - INITIALIZERS -
    
    public init(centerController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        
        self.view.clipsToBounds = true
        
        self.setCenterPanel(with: centerController)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - PUBLIC -
    
    public enum Side: UInt {
        case left
        case right
        case top
        case bottom
        case center
    }
    
    // MARK: Properties
    
    public private(set) var centerController: UIViewController?
    public private(set) var leftController: UIViewController?
    public private(set) var rightController: UIViewController?
    public private(set) var topController: UIViewController?
    public private(set) var bottomController: UIViewController?
    
    public var currentSide : Side = .center
    
    public var delegate: PanelControllerDelegate?
    
    public var layoutAnimationsDuration: TimeInterval = 0.25
    
    // MARK: API
    
    public func setPanel(to side: Side, animated: Bool = false) {
        self.delegate?.panelController(panelController: self, willTransitionTo: side)
        switch side {
        case .left:
            self.leftController?.beginAppearanceTransition(side != currentSide, animated: animated)
        case .right:
            self.rightController?.beginAppearanceTransition(side != currentSide, animated: animated)
        case .top:
            self.topController?.beginAppearanceTransition(side != currentSide, animated: animated)
        case .bottom:
            self.bottomController?.beginAppearanceTransition(side != currentSide, animated: animated)
        default:
            break
        }
        
        currentSide = side
        
        self.updateLayout(animated: animated) { finished in
            self.delegate?.panelController(panelController: self, didTransitionTo: side)
            switch side {
            case .left:
                self.leftController?.endAppearanceTransition()
            case .right:
                self.rightController?.endAppearanceTransition()
            case .top:
                self.topController?.endAppearanceTransition()
            case .bottom:
                self.bottomController?.endAppearanceTransition()
            case .center:
                break
            }
        }
        
    }
    
    // MARK: - PRIVATE -
    
    private var centerPanelConstraints: [NSLayoutConstraint]?
    
    private weak var centerPanelCenterXConstraint: NSLayoutConstraint!
    private weak var centerPanelCenterYConstraint: NSLayoutConstraint!
    
    typealias completionBlock = () -> Void
    
    // MARK: Panel setters
    
    public func setCenterPanel(with controller: UIViewController?) {
        guard let centerController = controller else { return self.removeController(controller: self.centerController) }
        guard !centerController.isEqual(self.centerController) else { return }
        
        self.removeController(controller: self.centerController)
        self.addChildViewController(centerController)
        centerController.willMove(toParentViewController: self)
        centerController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(centerController.view, at: 0)
        
        let widthConstraint = NSLayoutConstraint(item: self.view, attribute: .width, relatedBy: .equal, toItem: centerController.view, attribute: .width, multiplier: 1.0, constant: 0.0)
        let heightConstraint = NSLayoutConstraint(item: self.view, attribute: .height, relatedBy: .equal, toItem: centerController.view, attribute: .height, multiplier: 1.0, constant: 0.0)
        let centerXConstraint = NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal, toItem: centerController.view, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let centerYConstraint = NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal, toItem: centerController.view, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        
        self.centerPanelConstraints = [widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]
        self.centerPanelCenterXConstraint = centerXConstraint
        self.centerPanelCenterYConstraint = centerYConstraint
        
        self.view.addConstraints([widthConstraint, heightConstraint, centerXConstraint, centerYConstraint])
        
        centerController.didMove(toParentViewController: self)
        self.updateViewConstraints()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.centerController = centerController
    }
    
    public func setPanelController(controller: UIViewController?, for side: Side) {
        
        guard side != .center else {
            return
        }
        //
        // Check if we have a controller to remove
        //
        
        guard let controller = controller else {
            return self.removeController(controller: controllerForSide(side: side))
        }
        
        guard !controller.isEqual(controllerForSide(side: side)) else {
            return
        }
        
        guard let centerController = centerController else {
            return
        }
        
        self.removeController(controller: controllerForSide(side: side))
        self.addChildViewController(controller)
        controller.willMove(toParentViewController: self)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controller.view)
        
        //
        // Generate constraints width and height are always equal
        //
        
        let widthConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: controller.view, attribute: .width, multiplier: 1.0, constant: 0.0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: controller.view, attribute: .height, multiplier: 1.0, constant: 0.0)
        
        var constraints : [NSLayoutConstraint] = [ widthConstraint, heightConstraint ]
        
        switch side {
        case .left:
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .leading, relatedBy: .equal, toItem: controller.view, attribute: .trailing, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .centerY, relatedBy: .equal, toItem: controller.view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            
            leftController = controller
        case .right:
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .trailing, relatedBy: .equal, toItem: controller.view, attribute: .leading, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .centerY, relatedBy: .equal, toItem: controller.view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            
            rightController = controller
        case .top:
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .centerX, relatedBy: .equal, toItem: controller.view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .top, relatedBy: .equal, toItem: controller.view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
            
            topController = controller
        case .bottom:
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .centerX, relatedBy: .equal, toItem: controller.view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: centerController.view, attribute: .bottom, relatedBy: .equal, toItem: controller.view, attribute: .top, multiplier: 1.0, constant: 0.0))
            
            bottomController = controller
        default:
            break
        }
        
        self.view.addConstraints(constraints)
        
        controller.didMove(toParentViewController: self)
        self.updateViewConstraints()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    
    // MARK: Child controllers
    
    private func removeController(controller: UIViewController!) {
        guard controller != nil else {
            return
        }
        
        guard let side = sideForController(controller: controller) else {
            return
        }
        
        //
        // Clear out reference
        //
        
        switch side {
        case .left:
            leftController = nil
        case .right:
            rightController = nil
        case .top:
            topController = nil
        case .bottom:
            bottomController = nil
        case .center:
            centerController = nil
        }
        
        controller.willMove(toParentViewController: nil)
        controller.view.removeFromSuperview()
        controller.didMove(toParentViewController: nil)
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        guard let controller = container as? UIViewController else { return }
        guard sideForController(controller: controller) != nil else { return }
        
        //self.delegate?.panelController(panelController: self, willChangeSizeOfPanel: side)
        self.updateLayout(animated: true) { finished in
            //self.delegate?.panelController(panelController: self, didChangeSizeOfPanel: side)
        }
    }
    
    private func sideForController(controller: UIViewController) -> Side? {
        if controller.isEqual(self.leftController) {
            return .left
        }
        else if controller.isEqual(self.rightController) {
            return .right
        }
        else if controller.isEqual(self.topController) {
            return .top
        }
        else if controller.isEqual(self.bottomController) {
            return .bottom
        }
        else if controller.isEqual(self.centerController) {
            return .center
        }
        else {
            return nil
        }
    }
    
    private func controllerForSide(side: Side) -> UIViewController? {
        switch side {
        case .center:
            return centerController
        case .left:
            return leftController
        case .right:
            return rightController
        case .top:
            return topController
        case .bottom:
            return bottomController
        }
    }
    
    // MARK: Layout
    
    private func updateLayout(animated: Bool, duration: TimeInterval? = nil, completion: completionBlock? = nil) {
        let finalDuration = duration ?? self.layoutAnimationsDuration
        self.updateViewConstraints()
        guard animated else {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            completion?()
            return
        }
        
        UIView.animate(withDuration: finalDuration, animations: { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished { completion?()
            }
        })
    }
    
    override public func updateViewConstraints() {
        
        guard let centerPanelCenterXConstraint = centerPanelCenterXConstraint, let centerPanelCenterYConstraint = centerPanelCenterYConstraint else {
            super.updateViewConstraints()
            return
        }
        
        switch currentSide {
        case .center:
            centerPanelCenterXConstraint.constant = 0
            centerPanelCenterYConstraint.constant = 0
        case .left:
            centerPanelCenterXConstraint.constant = -view.bounds.width
            centerPanelCenterYConstraint.constant = 0
        case .right:
            centerPanelCenterXConstraint.constant = view.bounds.width
            centerPanelCenterYConstraint.constant = 0
        case .top:
            centerPanelCenterXConstraint.constant = 0
            centerPanelCenterYConstraint.constant =  -view.bounds.height
        case .bottom:
            centerPanelCenterXConstraint.constant = 0
            centerPanelCenterYConstraint.constant =  view.bounds.height
        }
        
        super.updateViewConstraints()
    }
    
    // MARK: Content sizes
    /*
    static let defaultPanelWidth = CGFloat(300)
    
    private func widthForController(controller: UIViewController?) -> CGFloat {
        if let width = controller?.preferredContentSize.width, width > 0 {
            return width
        }
        return PanelController.defaultPanelWidth
    }*/
    
}
