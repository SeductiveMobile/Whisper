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
    public static let imageSize: CGFloat = 40
    public static let titleHeight: CGFloat = 14
    public static var touchOffset: CGFloat = 80
    
    // container
    public static var height: CGFloat = 67
    public static var leftOffset: CGFloat = 10
    public static var rightOffset: CGFloat = 10
    public static var topOffset: CGFloat = 10
    public static var bottomOffset: CGFloat = 5
    public static var titlesSpace: CGFloat = 1
  }
    
    open fileprivate(set) lazy var containerStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.imageView, self.textStackView])
        view.alignment = .top
        view.axis = .horizontal
        view.spacing = 10
        view.distribution = .fill
        return view
    }()
    
    open fileprivate(set) lazy var textStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleTextView])
        view.alignment = .top
        view.axis = .vertical
        view.spacing = Dimensions.titlesSpace
        view.distribution = .fill
        return view
    }()

  open fileprivate(set) lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.background
    view.alpha = 0.98
    view.clipsToBounds = true

    return view
    }()

  open fileprivate(set) lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.isUserInteractionEnabled = true

    return view
    }()

  open fileprivate(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.imageSize / 2
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill

    return imageView
    }()

  open fileprivate(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.title
    label.textColor = ColorList.Shout.title
    label.numberOfLines = 1
    label.clipsToBounds = true
    label.lineBreakMode = .byWordWrapping

    return label
    }()
    
    open fileprivate(set) lazy var subtitleTextView: UITextView = {
        let textView = UITextView()
        textView.font = FontList.Shout.subtitle
        textView.textColor = ColorList.Shout.subtitle
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

  
    private var translationOffsetBegin: CGFloat? = 0
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
    
    addSubview(backgroundView)
    [containerStackView, indicatorView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      backgroundView.addSubview($0)
    }

    clipsToBounds = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5

    backgroundView.addGestureRecognizer(tapGestureRecognizer)
    addGestureRecognizer(panGestureRecognizer)

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

  open func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
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
    self.superview?.layoutIfNeeded()

    internalHeightConstraint?.constant = safeYOffsetCoordinate + Dimensions.height
    UIView.animate(withDuration: 0.35, animations: {
      self.superview?.layoutIfNeeded()
    })
  }

  // MARK: - Setup
    
    private func setupContainerConstraints(view: UIView) {
        internalLeadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor)
        internalTrailingConstraint = view.trailingAnchor.constraint(equalTo: trailingAnchor)
        internalTopConstraint = view.topAnchor.constraint(equalTo: topAnchor)
        
        internalLeadingConstraint?.isActive = true
        internalTrailingConstraint?.isActive = true
        internalTopConstraint?.isActive = true
    }
    
    public func setupConstraints() {
        //Self
        internalHeightConstraint = self.heightAnchor.constraint(equalToConstant: 0)
        internalHeightConstraint?.isActive = true
        
        //Background View
        self.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        //Image View
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: Dimensions.imageSize)
        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: Dimensions.imageSize)
        imageHeightConstraint.isActive = true
        imageHeightConstraint.priority = 999
        imageWidthConstraint.isActive = true
        imageWidthConstraint.priority = 999
        
        //Container View
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: safeLeftOffsetCoordinate).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -safeRightOffsetCoordinate).isActive = true
        containerStackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: Dimensions.topOffset + safeYOffsetCoordinate).isActive = true
        
        let bottomBackgroundViewConstraint = containerStackView.bottomAnchor.constraint(equalTo: indicatorView.topAnchor, constant: -Dimensions.bottomOffset)
        bottomBackgroundViewConstraint.isActive = true
        bottomBackgroundViewConstraint.priority = 999
        
        //Indicator View
        indicatorView.heightAnchor.constraint(equalToConstant: Dimensions.indicatorHeight).isActive = true
        indicatorView.widthAnchor.constraint(equalToConstant: Dimensions.indicatorWidth).isActive = true
        indicatorView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -Dimensions.indicatorBottomOffset).isActive = true
        
        //Title View
        titleLabel.heightAnchor.constraint(equalToConstant: Dimensions.titleHeight).isActive = true
    }
    

  // MARK: - Actions

    open func silent(moving: Bool = true) {
        _shoutView?.isUserInteractionEnabled = false
        if moving {
            self.internalHeightConstraint?.constant = 0
        }
    
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 0
            self.superview?.layoutIfNeeded()
          }, completion: { finished in
            self.completion?()
            self.displayTimer.invalidate()
            self.removeConstraints()
            self.removeFromSuperview()
        })
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
        
        if panGestureRecognizer.velocity(in: self).y < 0 || shouldSilent {
            silent()
        } else {
            internalHeightConstraint?.constant = safeYOffsetCoordinate + Dimensions.height
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.superview?.layoutIfNeeded()
            }, completion: nil)
        }
    }
  }


  // MARK: - Handling screen orientation

    @objc func orientationDidChange() {
        silent(moving: false)
    }
}
