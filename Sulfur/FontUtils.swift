/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public struct FontUtils {

    public enum Error: Swift.Error {

        case dataProviderConstructionFailed
        case postScriptNameUnavailable
    }

    public static func loadFont(at url: URL) throws -> String {
        let fontData = try Data(contentsOf: url)
        guard let dataProvider = CGDataProvider(data: fontData as CFData) else {
            throw Error.dataProviderConstructionFailed
        }
        let font = CGFont(dataProvider)
        var unmanagedError: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(font, &unmanagedError)
        if let unmanagedError = unmanagedError {
            throw unmanagedError.takeRetainedValue()
        }
        guard let fontName = (font.postScriptName ?? nil) as String? else {
            throw Error.postScriptNameUnavailable
        }
        return fontName
    }

    private init() { }
}
