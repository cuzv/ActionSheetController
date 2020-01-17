//
//  ActionSheetController.swift
//  ActionSheetController
//
//  Created by Shaw on 3/10/16.
//  Copyright ©2016 Shaw (https://github.com/cuzv).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import ModalTransitioning

public final class ActionSheetController: UIViewController {
    public private(set) var actions: [SheetAction] = []

    private static let fixedRowHeight: CGFloat = 50

    private let contentTitle: String
    private let contentTitleColor: UIColor

    private let cancelTitle: String
    private let cancelTitleColor: UIColor

    private var containerViewHeightConstraint: NSLayoutConstraint!
    private var containerViewAppearedVerticalConstraint: NSLayoutConstraint!
    private var containerViewDisAppearedVerticalConstraint: NSLayoutConstraint!

    private lazy var modalTransitioningDelegate = ModalTransitioningDelegate(delegate: self)

    public init(title: String = "", titleColor: UIColor = UIColor.gray, cancelTitle: String = "取消", cancelTitleColor: UIColor = UIColor.black) {
        contentTitle = title
        contentTitleColor = titleColor
        self.cancelTitle = cancelTitle
        self.cancelTitleColor = cancelTitleColor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = modalTransitioningDelegate
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private let labelBackedView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        return view
    }()

    private let topBorderline: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.rowHeight = ActionSheetController.fixedRowHeight
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.alwaysBounceVertical = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        return tableView
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.setBackgroundImage(UIImageFrom(color: UIColor.black.withAlphaComponent(0.2)), for: .highlighted)
        return button
    }()

    private let containerView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let coverView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        prepareConstraints()
        setupUserInterface()
        setupConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeStatusBarOrientation(sender:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    private func prepareConstraints() {
        containerViewAppearedVerticalConstraint = {
            if #available(iOS 11.0, *) {
                return containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            } else {
                return NSLayoutConstraint(
                    item: containerView,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: 0
                )
            }
        }()

        containerViewDisAppearedVerticalConstraint = {
            return NSLayoutConstraint(
                item: containerView,
                attribute: .top,
                relatedBy: .equal,
                toItem: view,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            )
        }()
    }

    private func setupUserInterface() {
        titleLabel.text = contentTitle
        titleLabel.textColor = contentTitleColor

        cancelButton.setTitleColor(cancelTitleColor, for: [])
        cancelButton.setTitle(cancelTitle, for: [])
        cancelButton.addTarget(self, action: #selector(ActionSheetController._dismiss), for: .touchUpInside)

        view.addSubview(coverView)
        coverView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActionSheetController.handleTapped(_:))))

        view.addSubview(containerView)
        containerView.contentView.addSubview(cancelButton)
        containerView.contentView.addSubview(tableView)
        containerView.contentView.addSubview(labelBackedView)
        labelBackedView.contentView.addSubview(topBorderline)
        containerView.contentView.addSubview(titleLabel)

        tableView.register(ActionSheetCell.self, forCellReuseIdentifier: ActionSheetCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupConstraints() {
        // coverView
        view.addConstraints([
            NSLayoutConstraint(item: coverView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coverView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coverView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coverView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // containerView
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|[containerView]|",
                options: [],
                metrics: nil,
                views: ["containerView": containerView]
            )
        )
        containerViewHeightConstraint = renewConstraint()
        view.addConstraints([
            containerViewDisAppearedVerticalConstraint,
            containerViewHeightConstraint
        ])

        // titleLabel
        if !contentTitle.isEmpty {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "|-16-[titleLabel]-16-|",
                    options: [],
                    metrics: nil,
                    views: ["titleLabel": titleLabel]
                )
            )
            containerView.addConstraints([
                NSLayoutConstraint(
                    item: titleLabel,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: containerView,
                    attribute: .top,
                    multiplier: 1,
                    constant: 20
                ),
                NSLayoutConstraint(
                    item: tableView,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: titleLabel,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: 20
                )
            ])

            // labelBackedView
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "|-0-[labelBackedView]-0-|",
                    options: [],
                    metrics: nil,
                    views: ["labelBackedView": labelBackedView]
                )
            )
            containerView.addConstraints([
                NSLayoutConstraint(
                    item: labelBackedView,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: containerView,
                    attribute: .top,
                    multiplier: 1,
                    constant: 0
                ),
                NSLayoutConstraint(
                    item: labelBackedView,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: tableView,
                    attribute: .top,
                    multiplier: 1,
                    constant: 0
                )
            ])

            // topBorderline
            labelBackedView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "|-0-[topBorderline]-0-|",
                    options: [],
                    metrics: nil,
                    views: ["topBorderline": topBorderline]
                )
            )
            labelBackedView.addConstraints([
                NSLayoutConstraint(
                    item: topBorderline,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1,
                    constant: 1.0 / UIScreen.main.scale
                ),
                NSLayoutConstraint(
                    item: topBorderline,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: labelBackedView,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: 0
                )
            ])
        } else {
            containerView.addConstraints([
                NSLayoutConstraint(
                    item: tableView,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: containerView,
                    attribute: .top,
                    multiplier: 1,
                    constant: 0
                )
            ])
        }

        // tableView
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|[tableView]|",
                options: [],
                metrics: nil,
                views: ["tableView": tableView]
            )
        )
        containerView.addConstraints([
            NSLayoutConstraint(
                item: tableView,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: cancelButton,
                attribute: .top,
                multiplier: 1,
                constant: -6
            )
        ])

        // cancelButton
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|[cancelButton]|",
                options: [],
                metrics: nil,
                views: ["cancelButton": cancelButton]
            )
        )
        containerView.addConstraints([
            NSLayoutConstraint(
                item: cancelButton,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: containerView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: cancelButton,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 0,
                constant: ActionSheetController.fixedRowHeight
            )
        ])
    }

    public override func updateViewConstraints() {
        view.removeConstraints([containerViewHeightConstraint])
        containerViewHeightConstraint = renewConstraint()
        view.addConstraint(containerViewHeightConstraint)
        super.updateViewConstraints()
    }

    @objc func handleChangeStatusBarOrientation(sender: Notification) {
        updateViewConstraints()
    }

    internal func dismissWithCompletion(_ completion: (() -> Void)?) {
        presentingViewController?.dismiss(animated: true, completion: completion)
    }

    @objc private func handleTapped(_ sender: UITapGestureRecognizer) {
        if !containerView.frame.contains(sender.location(in: view)) {
            dismissWithCompletion(nil)
        }
    }

    @objc private func _dismiss() {
        dismissWithCompletion(nil)
    }

    public func addAction(_ action: SheetAction) {
        actions.append(action)
    }

    // MARK: - UI

    private func renewConstraint() -> NSLayoutConstraint {
        func containerViewHeight() -> CGFloat {
            // 计算文本高度
            var textHeight: CGFloat = 0
            if !contentTitle.isEmpty {
                textHeight = 40
                let width = view.bounds.width - 32
                let boundingRect = (contentTitle as NSString).boundingRect(
                    with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
                    attributes: [.font: titleLabel.font!],
                    context: nil
                )
                textHeight += boundingRect.size.height
            }
            let bottomHeight = ActionSheetController.fixedRowHeight + 6 // cancel + spacing
            let height = CGFloat(actions.count) * ActionSheetController.fixedRowHeight + textHeight
            let maxHeight = floor(view.bounds.height * CGFloat(0.67) / ActionSheetController.fixedRowHeight) * ActionSheetController.fixedRowHeight + textHeight
            return (height < maxHeight ? height : maxHeight) + bottomHeight
        }

        return NSLayoutConstraint(
            item: containerView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0,
            constant: containerViewHeight()
        )
    }
}

// MARK: - ModalTransitioning

extension ActionSheetController: ModalTransitioning {
    public func willPresentFrom(viewController: UIViewController) {
        view.removeConstraint(containerViewDisAppearedVerticalConstraint)
        view.addConstraint(containerViewAppearedVerticalConstraint)
        coverView.alpha = 0
    }

    public func presentingFrom(viewController: UIViewController) {
        view.layoutIfNeeded()
        coverView.alpha = 1
    }

    public func willDismissTo(viewController: UIViewController) {
        view.removeConstraint(containerViewAppearedVerticalConstraint)
        view.addConstraint(containerViewDisAppearedVerticalConstraint)
    }

    public func dismissingTo(viewController: UIViewController) {
        view.layoutIfNeeded()
        coverView.alpha = 0
    }
}

// MARK: - Table view methods

extension ActionSheetController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActionSheetCell.identifier, for: indexPath) as? ActionSheetCell  else {
            fatalError("dequeue cell failure.")
        }

        cell.setupData(actions[(indexPath as NSIndexPath).row])

        return cell
    }
}

extension ActionSheetController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let action = actions[(indexPath as NSIndexPath).row]
        dismissWithCompletion { () -> Void in
            action.handler?(action)
        }
    }
}

// MARK: - ActionSheetCell

private final class ActionSheetCell: UITableViewCell {
    fileprivate static var identifier: String {
        return NSStringFromClass(self)
    }

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUserInterface()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUserInterface() {
        layoutMargins = UIEdgeInsets.zero
        separatorInset = UIEdgeInsets.zero
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            return view
        }()

        contentView.addSubview(contentLabel)

        let views = ["label": contentLabel]
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|-8-[label]-8-|",
                options: [],
                metrics: nil,
                views: views
            )
        )
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[label]|",
                options: [],
                metrics: nil,
                views: views
            )
        )
    }

    fileprivate func setupData(_ action: SheetAction) {
        contentLabel.text = action.title
        contentLabel.textColor = action.titleColor
    }
}

private func UIImageFrom(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
    UIGraphicsBeginImageContext(size)
    guard let context = UIGraphicsGetCurrentContext() else {
        return nil
    }
    context.setFillColor(color.cgColor)
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    context.fill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image!
}
