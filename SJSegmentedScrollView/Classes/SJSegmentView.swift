//
//  SJSegmentView.swift
//  SJSegmentedScrollView
//
//  Created by Subins Jose on 10/06/16.
//  Copyright © 2016 Subins Jose. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
//    associated documentation files (the "Software"), to deal in the Software without restriction,
//    including without limitation the rights to use, copy, modify, merge, publish, distribute,
//    sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or
//    substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

class SJSegmentView: UIScrollView {
    
    var selectedSegmentViewColor: UIColor? {
        didSet {
            selectedSegmentView?.backgroundColor = selectedSegmentViewColor
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            for segment in segments {
                segment.titleColor(titleColor!)
            }
        }
    }
    
    var selectedTitleColor: UIColor? {
        didSet {
            for segment in segments {
                segment.selectedTitleColor(selectedTitleColor)
            }
        }
    }
    
    var segmentBackgroundColor: UIColor? {
        didSet {
            for segment in segments {
                segment.backgroundColor = segmentBackgroundColor
            }
        }
    }
    
    var shadow: SJShadow? {
        didSet {
            if let shadow = shadow {
                layer.shadowOffset = shadow.offset
                layer.shadowColor = shadow.color.cgColor
                layer.shadowRadius = shadow.radius
                layer.shadowOpacity = shadow.opacity
                layer.masksToBounds = false;
            }
        }
    }
    
    var font: UIFont?
    var selectedSegmentViewHeight: CGFloat?
    let kSegmentViewTagOffset = 100
    var segmentViewOffsetWidth: CGFloat = 10.0
    var segments = [SJSegmentTab]()
    var segmentContentView: UIView?
    var didSelectSegmentAtIndex: DidSelectSegmentAtIndex?
    var selectedSegmentView: UIView?
    var xPosConstraints: NSLayoutConstraint?
    var contentViewWidthConstraint: NSLayoutConstraint?
    var selSegmentWidthConstraint: NSLayoutConstraint?
    var selSegmentLeftConstraint: NSLayoutConstraint?
    var contentSubViewWidthConstraints = [NSLayoutConstraint]()
	var controllers: [UIViewController]?
    
    var contentView: SJContentView? {
        didSet {
            contentView!.addObserver(self,
                                     forKeyPath: "contentOffset",
                                     options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old],
                                     context: nil)
        }
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)

		showsHorizontalScrollIndicator = false
		showsVerticalScrollIndicator = false
		bounces = false


		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(SJSegmentView.didChangeSegmentIndex(_:)),
		                                       name: NSNotification.Name("DidChangeSegmentIndex"),
		                                       object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        contentView!.removeObserver(self,
                                    forKeyPath: "contentOffset",
                                    context: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                            name:NSNotification.Name("DidChangeSegmentIndex"),
                                                            object: nil)
    }
    
    @objc func didChangeSegmentIndex(_ notification: Notification) {
        
        //deselect previous buttons
        for button in segments {
            button.isSelected = false
        }
        
        // select current button
        guard let index = notification.object as? Int else { return }

		if index < segments.count {
			let button = segments[index]
			button.isSelected = true
		}
        
        let width = widthForSegment(controller: controllers![index])
        print(self.segments[index].frame.origin.x)
        print(index)
        print(self.offset(at: index))
        UIView.animate(withDuration: 0.3) {
            self.selSegmentWidthConstraint?.constant = width - 40
            self.selSegmentLeftConstraint?.constant = self.offset(at: index) + 20
            self.layoutIfNeeded()
        }
    }

    func setSegmentsView(_ frame: CGRect) {

        createSegmentContentView()
        
        var index = 0
        for controller in controllers! {
            
            createSegmentFor(controller, index: index)
            index += 1
        }
        
        createSelectedSegmentView()
        
        //Set first button as selected
        let button = segments.first!
        button.isSelected = true
    }
    
    func createSegmentContentView() {
        
        segmentContentView = UIView(frame: CGRect.zero)
        segmentContentView!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentContentView!)
        
        let contentViewWidth = totalWidth()
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|",
                                                                                   options: [],
                                                                                   metrics: nil,
                                                                                   views: ["contentView": segmentContentView!,
                                                                                    "mainView": self])
        addConstraints(horizontalConstraints)
        
        contentViewWidthConstraint = NSLayoutConstraint(item: segmentContentView!,
                                                        attribute: .width,
                                                        relatedBy: .equal,
                                                        toItem: nil,
                                                        attribute: .notAnAttribute,
                                                        multiplier: 1.0,
                                                        constant: contentViewWidth)
        addConstraint(contentViewWidthConstraint!)
        
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView(==mainView)]|",
                                                                                 options: [],
                                                                                 metrics: nil,
                                                                                 views: ["contentView": segmentContentView!,
                                                                                    "mainView": self])
        addConstraints(verticalConstraints)
    }
    
    func createSegmentFor(_ controller: UIViewController, index: Int) {
        
        let width: CGFloat = widthForSegment(controller: controller)
        let segmentView = getSegmentTabForController(controller)
        segmentView.tag = (index + kSegmentViewTagOffset)
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentContentView!.addSubview(segmentView)
        
        if segments.count == 0 {
            
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]",
                                                                                       options: [],
                                                                                       metrics: nil,
                                                                                       views: ["view": segmentView])
            segmentContentView!.addConstraints(horizontalConstraints)
            
        } else {
            
            let previousView = segments.last
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[previousView]-0-[view]",
                                                                                       options: [],
                                                                                       metrics: nil,
                                                                                       views: ["view": segmentView,
                                                                                        "previousView": previousView!])
            segmentContentView!.addConstraints(horizontalConstraints)
        }
        
        let widthConstraint = NSLayoutConstraint(item: segmentView,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1.0,
                                                 constant: width)
        segmentContentView!.addConstraint(widthConstraint)
        contentSubViewWidthConstraints.append(widthConstraint)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                                 options: [],
                                                                                 metrics: nil,
                                                                                 views: ["view": segmentView])
        segmentContentView!.addConstraints(verticalConstraints)
        segments.append(segmentView)
    }
    
    func createSelectedSegmentView() {
        
        let segmentView = UIView()
        segmentView.backgroundColor = selectedSegmentViewColor
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentView.layer.cornerRadius = 2.0
        segmentView.clipsToBounds = true
        segmentContentView!.addSubview(segmentView)
        selectedSegmentView = segmentView
        
        let width = widthForSegment(controller: controllers!.first!)
        selSegmentWidthConstraint = NSLayoutConstraint(item: segmentView,
                                                    attribute: .width,
                                                    relatedBy: .equal,
                                                    toItem: nil,
                                                    attribute: .notAnAttribute,
                                                    multiplier: 1.0,
                                                    constant: width - 40.0)
        segmentContentView!.addConstraint(selSegmentWidthConstraint!)

        selSegmentLeftConstraint = segmentView.leftAnchor.constraint(equalTo: segmentContentView!.leftAnchor, constant: 20)
        selSegmentLeftConstraint?.isActive = true
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view(height)]|",
                                                                                 options: [],
                                                                                 metrics: ["height": selectedSegmentViewHeight!],
                                                                                 views: ["view": segmentView])
        segmentContentView!.addConstraints(verticalConstraints)
    }
    
    func getSegmentTabForController(_ controller: UIViewController) -> SJSegmentTab {

		var segmentTab: SJSegmentTab?

		if controller.navigationItem.titleView != nil {
			segmentTab = SJSegmentTab.init(view: controller.navigationItem.titleView!)
		} else {

			if let title = controller.title {
				segmentTab = SJSegmentTab.init(title: title)
			} else {
				segmentTab = SJSegmentTab.init(title: "")
			}

			segmentTab?.backgroundColor = segmentBackgroundColor
			segmentTab?.titleColor(titleColor!)
            segmentTab?.selectedTitleColor(selectedTitleColor!)
			segmentTab?.titleFont(font!)
		}

		segmentTab?.didSelectSegmentAtIndex = didSelectSegmentAtIndex

        return segmentTab!
    }
    
    func totalWidth() -> CGFloat {
        var width: CGFloat = 0
        for controller in controllers! {
            width += widthForSegment(controller: controller)
        }
        return width
    }

    func widthForSegment(controller: UIViewController) -> CGFloat {
        var width: CGFloat = 0.0
        if let title = controller.title {
            width = title.widthWithConstrainedWidth(.greatestFiniteMagnitude,
                                                    font: font!)
        }

		return width + 40.0
	}
    
    func offset(at index: Int) -> CGFloat {
        var offset: CGFloat = 0
        for (i, controller) in controllers!.enumerated() {
            if (i < index) {
                offset += widthForSegment(controller: controller)
            }
        }
        return offset
    }
    
	override func observeValue(forKeyPath keyPath: String?,
	                           of object: Any?,
	                           change: [NSKeyValueChangeKey : Any]?,
	                           context: UnsafeMutableRawPointer?) {
        
        if let change = change as [NSKeyValueChangeKey : AnyObject]? {
            if let old = change[NSKeyValueChangeKey.oldKey], let new = change[NSKeyValueChangeKey.newKey] {
                if !(old.isEqual(new)) {
                    
                    //update selected segment view x position
                    let scrollView = object as? UIScrollView
                    var changeOffset = (scrollView?.contentSize.width)! / contentSize.width
                    let value = (scrollView?.contentOffset.x)! / changeOffset
                    
                    if !value.isNaN {
//                        selectedSegmentView?.frame.origin.x = (scrollView?.contentOffset.x)! / changeOffset
                    }
                    
                    //update segment offset x position
                    let segmentScrollWidth = contentSize.width - bounds.width
                    let contentScrollWidth = scrollView!.contentSize.width - scrollView!.bounds.width
                    changeOffset = segmentScrollWidth / contentScrollWidth
                    contentOffset.x = (scrollView?.contentOffset.x)! * changeOffset
                }
            }
        }
    }
    
    
    
    func didChangeParentViewFrame(_ frame: CGRect) {
        
        contentViewWidthConstraint?.constant = totalWidth()
    }
}
