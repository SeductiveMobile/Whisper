import UIKit

var shoutView: ShoutView {
    _shoutView?.silent(moving: false)
    let view = ShoutView()
    _shoutView = view
    return view
}
fileprivate var _shoutView: ShoutView? = nil

open class ShoutView: UIView {

  public struct Dimensions {
    public static let indicatorHeight: CGFloat = 3
    public static var indicatorBottomOffset: CGFloat = 5
    public static let indicatorWidth: CGFloat = 33
    public static let imageSize: CGFloat = 37
    public static let imageCornerRadius: CGFloat = 6.0
    public static let titleHeight: CGFloat = 14
    public static var touchOffset: CGFloat = 80
    
    public static var subtitleMaxLinesCount = 1
    public static var containerSpacing: CGFloat = 10.0
    
    // container
    public static var height: CGFloat = 65
    public static var leftOffset: CGFloat = 10
    public static var rightOffset: CGFloat = 10
    public static var topOffset: CGFloat = 14
    public static var bottomOffset: CGFloat = 14
    public static var titlesSpace: CGFloat = 1
    public static var topInset: CGFloat = 26.0
    
  }
    
    fileprivate(set) lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    open fileprivate(set) lazy var containerStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.imageView, self.textStackView])
        view.alignment = .center
        view.axis = .horizontal
        view.spacing = Dimensions.containerSpacing
        view.distribution = .fill
        return view
    }()
    
    open fileprivate(set) lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleTextView])
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = Dimensions.titlesSpace
        stackView.distribution = .fill
        stackView.spacing = 5.0
        return stackView
    }()

  open fileprivate(set) lazy var backgroundView: VisualEffectView = {
    let view = VisualEffectView()
    let color = UIColor(red: 69.0/255.0, green:  73.0/255.0, blue:  77.0/255.0, alpha: 1.0)
    view.tint(color, blurRadius: 6)
    
    view.clipsToBounds = true

    return view
    }()

  open fileprivate(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.imageCornerRadius
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill

    return imageView
    }()

  open fileprivate(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
    label.textColor = .white
    label.numberOfLines = 1
    label.clipsToBounds = true
    label.lineBreakMode = .byWordWrapping

    return label
    }()
    
    open fileprivate(set) lazy var subtitleTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14.0)
        textView.textColor = .white
        textView.isScrollEnabled = false
        textView.clipsToBounds = true
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.isUserInteractionEnabled = false
        return textView
    }()

  open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))

    return gesture
    }()

  open fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))

    return gesture
    }()

  open fileprivate(set) var announcement: Announcement?
  open fileprivate(set) var displayTimer = Timer()
  open fileprivate(set) var shouldSilent = false
  open fileprivate(set) var completion: (() -> ())?

  
    private var translationOffsetBegin: CGFloat? = nil
    private var internalHeightConstraint: NSLayoutConstraint?
    private var internalLeadingConstraint: NSLayoutConstraint?
    private var internalTrailingConstraint: NSLayoutConstraint?
    private var internalTopConstraint: NSLayoutConstraint?
    private weak var windowView: UIView? = UIApplication.shared.keyWindow
    
    private var panGestureActive: Bool {
        return translationOffsetBegin != nil
    }
    
    //MARK: - Safe Area
    
    var safeYOffsetCoordinate: CGFloat {
        if let safeArea = self.windowView?.safeYCoordinate, safeArea > 0 {
            return safeArea
        }
        return Dimensions.topOffset
    }
    
    var safeLeftOffsetCoordinate: CGFloat {
        if let safeArea = self.windowView?.safeLeftCoordinate, safeArea > 0 {
            return safeArea
        }
        return Dimensions.leftOffset
    }
    
    var safeRightOffsetCoordinate: CGFloat {
        if let safeArea = self.windowView?.safeRightCoordinate, safeArea > 0 {
            return safeArea
        }
        return Dimensions.rightOffset
    }
    
    var heightToFillContent: CGFloat {
        let subtitleHeight = subtitleTextView.contentSize.height
        return Dimensions.topOffset + Dimensions.titleHeight + Dimensions.titlesSpace
            + subtitleHeight + Dimensions.bottomOffset + Dimensions.indicatorHeight
            + Dimensions.indicatorBottomOffset
    }

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)
    containerView.addSubview(backgroundView)
    addSubview(containerView)
    
    [containerStackView].forEach {
        backgroundView.contentView.addSubview($0)
    }

    containerView.clipsToBounds = true
    containerView.layer.cornerRadius = 10.0

    backgroundView.addGestureRecognizer(tapGestureRecognizer)
//    backgroundView.addGestureRecognizer(panGestureRecognizer)

    NotificationCenter.default.addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    setupConstraints()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    print("Deinit ShoutView")
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  // MARK: - Configuration

  open func craft(_ announcement: Announcement, completion: (() -> ())?) {
    shouldSilent = false
    configureView(announcement)
    shout()
    

    self.completion = completion
  }

  open func configureView(_ announcement: Announcement) {
    self.announcement = announcement
    imageView.image = announcement.image
    imageView.isHidden = announcement.image == nil
    titleLabel.text = announcement.title
    subtitleTextView.text = announcement.subtitle

    displayTimer.invalidate()
    displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
      target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)
  }

  open func shout() {
    guard let superView = self.windowView else {
        return
    }
    superView.addSubview(self)
    setupContainerConstraints(view: superView)
    self.layoutIfNeeded()

    internalHeightConstraint?.constant = Dimensions.height
    internalTopConstraint?.constant = -Dimensions.topInset-safeYOffsetCoordinate
    
    
    UIView.animate(withDuration: 1, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: {
        self.layoutIfNeeded()
    }, completion: nil)
  }

  // MARK: - Setup
    
    private func setupContainerConstraints(view: UIView) {
        // Self
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        // Container View
        internalLeadingConstraint = view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -10.0)
        internalTrailingConstraint = view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 10.0)
        internalTopConstraint = view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Dimensions.topInset+Dimensions.height)
        
        internalLeadingConstraint?.isActive = true
        internalTrailingConstraint?.isActive = true
        internalTopConstraint?.isActive = true
    }
    
    public func setupConstraints() {
        //Self
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: Dimensions.height).isActive = true
        
        //Container View
        containerView.translatesAutoresizingMaskIntoConstraints = false
        internalHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: Dimensions.height)
        internalHeightConstraint?.isActive = true
        
        //Background View
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        
        //Image View
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: Dimensions.imageSize)
        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: Dimensions.imageSize)
        imageHeightConstraint.priority = UILayoutPriority(rawValue: 999)
        imageWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        imageWidthConstraint.isActive = true
        imageHeightConstraint.isActive = true
        
        //Container View
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 10.0),
            containerStackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -10.0),
            containerStackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: Dimensions.topOffset),
            containerStackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -Dimensions.bottomOffset)
            ])
        
        let heightConstraint = maxSubtitleHeight(font: subtitleTextView.font!, widthOffset: Dimensions.imageSize + Dimensions.containerSpacing + Dimensions.leftOffset + Dimensions.rightOffset)
        subtitleTextView.heightAnchor.constraint(equalToConstant: heightConstraint).isActive = true
        
        //Title View
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalToConstant: Dimensions.titleHeight).isActive = true
    }
    
    
    // MARK: - Util
    
    private func maxSubtitleHeight(font: UIFont, widthOffset: CGFloat) -> CGFloat {
        guard ShoutView.Dimensions.subtitleMaxLinesCount > 0 else { return 0.0 }
        let width = UIScreen.main.bounds.width - widthOffset
        guard ShoutView.Dimensions.subtitleMaxLinesCount > 1 else {
            return "".height(withConstrainedWidth: width, font: font)
        }
        let lines: String = Array.init(repeating: "\n", count: ShoutView.Dimensions.subtitleMaxLinesCount-1).joined()
        return lines.height(withConstrainedWidth: UIScreen.main.bounds.width - widthOffset, font: font)
    }

  // MARK: - Actions

    open func silent(moving: Bool = true, animated: Bool = true) {
        _shoutView?.isUserInteractionEnabled = false
        
        let clean = {
            if _shoutView == self {
                _shoutView = nil
            }
            self.completion?()
            self.displayTimer.invalidate()
            self.removeConstraints()
            self.removeFromSuperview()
        }
        
        if !moving {
            UIView.animate(withDuration: 1, animations: {
                self.alpha = 0
            }, completion: { finished in
                clean()
            })
            return
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.internalTopConstraint?.constant = Dimensions.topInset+Dimensions.height+self.safeYOffsetCoordinate
                self.layoutIfNeeded()
            }, completion: { finished in
                clean()
            })
        }
        
        
    }
    
    private func removeConstraints() {
        internalTopConstraint.flatMap(removeConstraint)
        internalLeadingConstraint.flatMap(removeConstraint)
        internalTrailingConstraint.flatMap(removeConstraint)
        internalTopConstraint = nil
        internalLeadingConstraint = nil
        internalTrailingConstraint = nil
    }

  // MARK: - Timer methods

    @objc open func displayTimerDidFire() {
    guard !panGestureActive else {
        shouldSilent = true
        return
    }
    silent()
  }

  // MARK: - Gesture methods

  @objc fileprivate func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }
  
  @objc private func handlePanGestureRecognizer() {
    let translationY = panGestureRecognizer.translation(in: self).y

    if panGestureRecognizer.state == .began {
        translationOffsetBegin = translationY
        subtitleTextView.isScrollEnabled = true

    } else if panGestureRecognizer.state == .changed {
        guard let translationOffsetBegin = translationOffsetBegin else { return }
        let diff = translationOffsetBegin - translationY
        let newHeight = Dimensions.height - diff
        let scrollEnabled: Bool
        
        if diff >= 0 {
            internalHeightConstraint?.constant = Dimensions.height + safeYOffsetCoordinate
            scrollEnabled = false
        } else if newHeight <= self.heightToFillContent {
            internalHeightConstraint?.constant = newHeight + safeYOffsetCoordinate
            scrollEnabled = true
        } else {
            internalHeightConstraint?.constant = safeYOffsetCoordinate + self.heightToFillContent - diff/20
            scrollEnabled = true
        }
        subtitleTextView.isScrollEnabled = scrollEnabled
        superview?.layoutIfNeeded()
        
    } else {
        translationOffsetBegin = nil
        subtitleTextView.isScrollEnabled = false
        print("\(translationY)")
        if panGestureRecognizer.velocity(in: self).y < 0 || shouldSilent {
            silent()
        } else {
            internalHeightConstraint?.constant = safeYOffsetCoordinate + Dimensions.height
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }
  }


  // MARK: - Handling screen orientation

    @objc func orientationDidChange() {
        silent(moving: false)
    }
}


