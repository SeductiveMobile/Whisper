import UIKit

extension UIView {
    var safeYCoordinate: CGFloat? {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.top
        } else {
            return nil
        }
    }
    
    var safeLeftCoordinate: CGFloat? {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.left
        } else {
            return nil
        }
    }
    
    var safeRightCoordinate: CGFloat? {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.right
        } else {
            return nil
        }
    }

  var isiPhoneX: Bool {
    return safeYCoordinate ?? 0 > 20
  }
}
