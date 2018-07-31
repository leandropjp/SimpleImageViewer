import QuartzCore
import AVFoundation

struct Utilities {
    static func rect(forSize size: CGSize) -> CGRect {
        return CGRect(origin: .zero, size: size)
    }

    static func aspectFitRect(forSize size: CGSize, insideRect: CGRect) -> CGRect {
        return AVMakeRect(aspectRatio: size, insideRect: insideRect)
    }

    static func aspectFillRect(forSize size: CGSize, insideRect: CGRect) -> CGRect {
        let imageRatio = size.width / size.height
        let insideRectRatio = insideRect.width / insideRect.height
        if imageRatio > insideRectRatio {
            return CGRect(x: 0, y: 0, width: floor(insideRect.height * imageRatio), height: insideRect.height)
        } else {
            return CGRect(x: 0, y: 0, width: insideRect.width, height: floor(insideRect.width / imageRatio))
        }
    }
}
