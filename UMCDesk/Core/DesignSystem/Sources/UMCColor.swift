//
//  UMCColor.swift
//  CoreDesignSystem
//
//  Created by euijjang97 on 10/8/26.
//

import SwiftUI

public enum UMCColor {
    public enum Primitives {
        /// Primitives/Base/White
        public static let white = Color("Primitives/Base/White", bundle: .module)

        /// Primitives/Base/Black
        public static let black = Color("Primitives/Base/Black", bundle: .module)

        /// Primitives/Grey/TealGrey-50
        public static let tealGrey50 = Color("Primitives/Grey/TealGrey-50", bundle: .module)

        /// Primitives/Grey/TealGrey-75
        public static let tealGrey75 = Color("Primitives/Grey/TealGrey-75", bundle: .module)

        /// Primitives/Grey/TealGrey-100
        public static let tealGrey100 = Color("Primitives/Grey/TealGrey-100", bundle: .module)

        /// Primitives/Grey/TealGrey-200
        public static let tealGrey200 = Color("Primitives/Grey/TealGrey-200", bundle: .module)

        /// Primitives/Grey/TealGrey-300
        public static let tealGrey300 = Color("Primitives/Grey/TealGrey-300", bundle: .module)

        /// Primitives/Grey/TealGrey-400
        public static let tealGrey400 = Color("Primitives/Grey/TealGrey-400", bundle: .module)

        /// Primitives/Grey/TealGrey-500
        public static let tealGrey500 = Color("Primitives/Grey/TealGrey-500", bundle: .module)

        /// Primitives/Grey/TealGrey-600
        public static let tealGrey600 = Color("Primitives/Grey/TealGrey-600", bundle: .module)

        /// Primitives/Grey/TealGrey-700
        public static let tealGrey700 = Color("Primitives/Grey/TealGrey-700", bundle: .module)

        /// Primitives/Grey/TealGrey-800
        public static let tealGrey800 = Color("Primitives/Grey/TealGrey-800", bundle: .module)

        /// Primitives/Grey/TealGrey-900
        public static let tealGrey900 = Color("Primitives/Grey/TealGrey-900", bundle: .module)

        /// Primitives/Teal/Teal-50
        public static let teal50 = Color("Primitives/Teal/Teal-50", bundle: .module)

        /// Primitives/Teal/Teal-75
        public static let teal75 = Color("Primitives/Teal/Teal-75", bundle: .module)

        /// Primitives/Teal/Teal-100
        public static let teal100 = Color("Primitives/Teal/Teal-100", bundle: .module)

        /// Primitives/Teal/Teal-200
        public static let teal200 = Color("Primitives/Teal/Teal-200", bundle: .module)

        /// Primitives/Teal/Teal-300
        public static let teal300 = Color("Primitives/Teal/Teal-300", bundle: .module)

        /// Primitives/Teal/Teal-400
        public static let teal400 = Color("Primitives/Teal/Teal-400", bundle: .module)

        /// Primitives/Teal/Teal-500
        public static let teal500 = Color("Primitives/Teal/Teal-500", bundle: .module)

        /// Primitives/Teal/Teal-600
        public static let teal600 = Color("Primitives/Teal/Teal-600", bundle: .module)

        /// Primitives/Teal/Teal-700
        public static let teal700 = Color("Primitives/Teal/Teal-700", bundle: .module)

        /// Primitives/Teal/Teal-800
        public static let teal800 = Color("Primitives/Teal/Teal-800", bundle: .module)

        /// Primitives/Teal/Teal-900
        public static let teal900 = Color("Primitives/Teal/Teal-900", bundle: .module)

        /// Primitives/Red/Red-50
        public static let red50 = Color("Primitives/Red/Red-50", bundle: .module)

        /// Primitives/Red/Red-100
        public static let red100 = Color("Primitives/Red/Red-100", bundle: .module)

        /// Primitives/Red/Red-200
        public static let red200 = Color("Primitives/Red/Red-200", bundle: .module)

        /// Primitives/Red/Red-300
        public static let red300 = Color("Primitives/Red/Red-300", bundle: .module)

        /// Primitives/Red/Red-400
        public static let red400 = Color("Primitives/Red/Red-400", bundle: .module)

        /// Primitives/Red/Red-500
        public static let red500 = Color("Primitives/Red/Red-500", bundle: .module)

        /// Primitives/Red/Red-600
        public static let red600 = Color("Primitives/Red/Red-600", bundle: .module)

        /// Primitives/Red/Red-700
        public static let red700 = Color("Primitives/Red/Red-700", bundle: .module)

        /// Primitives/Red/Red-800
        public static let red800 = Color("Primitives/Red/Red-800", bundle: .module)

        /// Primitives/Red/Red-900
        public static let red900 = Color("Primitives/Red/Red-900", bundle: .module)

        /// Primitives/Yellow/Yellow-50
        public static let yellow50 = Color("Primitives/Yellow/Yellow-50", bundle: .module)

        /// Primitives/Yellow/Yellow-100
        public static let yellow100 = Color("Primitives/Yellow/Yellow-100", bundle: .module)

        /// Primitives/Yellow/Yellow-200
        public static let yellow200 = Color("Primitives/Yellow/Yellow-200", bundle: .module)

        /// Primitives/Yellow/Yellow-300
        public static let yellow300 = Color("Primitives/Yellow/Yellow-300", bundle: .module)

        /// Primitives/Yellow/Yellow-400
        public static let yellow400 = Color("Primitives/Yellow/Yellow-400", bundle: .module)

        /// Primitives/Yellow/Yellow-500
        public static let yellow500 = Color("Primitives/Yellow/Yellow-500", bundle: .module)

        /// Primitives/Yellow/Yellow-600
        public static let yellow600 = Color("Primitives/Yellow/Yellow-600", bundle: .module)

        /// Primitives/Yellow/Yellow-700
        public static let yellow700 = Color("Primitives/Yellow/Yellow-700", bundle: .module)

        /// Primitives/Yellow/Yellow-800
        public static let yellow800 = Color("Primitives/Yellow/Yellow-800", bundle: .module)

        /// Primitives/Yellow/Yellow-900
        public static let yellow900 = Color("Primitives/Yellow/Yellow-900", bundle: .module)

        /// Primitives/Green/Green-50
        public static let green50 = Color("Primitives/Green/Green-50", bundle: .module)

        /// Primitives/Green/Green-100
        public static let green100 = Color("Primitives/Green/Green-100", bundle: .module)

        /// Primitives/Green/Green-200
        public static let green200 = Color("Primitives/Green/Green-200", bundle: .module)

        /// Primitives/Green/Green-300
        public static let green300 = Color("Primitives/Green/Green-300", bundle: .module)

        /// Primitives/Green/Green-400
        public static let green400 = Color("Primitives/Green/Green-400", bundle: .module)

        /// Primitives/Green/Green-500
        public static let green500 = Color("Primitives/Green/Green-500", bundle: .module)

        /// Primitives/Green/Green-600
        public static let green600 = Color("Primitives/Green/Green-600", bundle: .module)

        /// Primitives/Green/Green-700
        public static let green700 = Color("Primitives/Green/Green-700", bundle: .module)

        /// Primitives/Green/Green-800
        public static let green800 = Color("Primitives/Green/Green-800", bundle: .module)

        /// Primitives/Green/Green-900
        public static let green900 = Color("Primitives/Green/Green-900", bundle: .module)

        /// Primitives/Violet/Violet-50
        public static let violet50 = Color("Primitives/Violet/Violet-50", bundle: .module)

        /// Primitives/Violet/Violet-100
        public static let violet100 = Color("Primitives/Violet/Violet-100", bundle: .module)

        /// Primitives/Violet/Violet-500
        public static let violet500 = Color("Primitives/Violet/Violet-500", bundle: .module)

        /// Primitives/Violet/Violet-600
        public static let violet600 = Color("Primitives/Violet/Violet-600", bundle: .module)

        /// Primitives/Purple/Purple-50
        public static let purple50 = Color("Primitives/Purple/Purple-50", bundle: .module)

        /// Primitives/Purple/Purple-100
        public static let purple100 = Color("Primitives/Purple/Purple-100", bundle: .module)

        /// Primitives/Purple/Purple-500
        public static let purple500 = Color("Primitives/Purple/Purple-500", bundle: .module)

        /// Primitives/Purple/Purple-600
        public static let purple600 = Color("Primitives/Purple/Purple-600", bundle: .module)

        /// Primitives/Pink/Pink-50
        public static let pink50 = Color("Primitives/Pink/Pink-50", bundle: .module)

        /// Primitives/Pink/Pink-100
        public static let pink100 = Color("Primitives/Pink/Pink-100", bundle: .module)

        /// Primitives/Pink/Pink-500
        public static let pink500 = Color("Primitives/Pink/Pink-500", bundle: .module)

        /// Primitives/Pink/Pink-600
        public static let pink600 = Color("Primitives/Pink/Pink-600", bundle: .module)

        /// Primitives/Cobalt/Cobalt-50
        public static let cobalt50 = Color("Primitives/Cobalt/Cobalt-50", bundle: .module)

        /// Primitives/Cobalt/Cobalt-100
        public static let cobalt100 = Color("Primitives/Cobalt/Cobalt-100", bundle: .module)

        /// Primitives/Cobalt/Cobalt-500
        public static let cobalt500 = Color("Primitives/Cobalt/Cobalt-500", bundle: .module)

        /// Primitives/Cobalt/Cobalt-600
        public static let cobalt600 = Color("Primitives/Cobalt/Cobalt-600", bundle: .module)

        /// Primitives/Blue/Blue-50
        public static let blue50 = Color("Primitives/Blue/Blue-50", bundle: .module)

        /// Primitives/Blue/Blue-100
        public static let blue100 = Color("Primitives/Blue/Blue-100", bundle: .module)

        /// Primitives/Blue/Blue-500
        public static let blue500 = Color("Primitives/Blue/Blue-500", bundle: .module)

        /// Primitives/Blue/Blue-600
        public static let blue600 = Color("Primitives/Blue/Blue-600", bundle: .module)

        /// Primitives/Brown/Brown-50
        public static let brown50 = Color("Primitives/Brown/Brown-50", bundle: .module)

        /// Primitives/Brown/Brown-100
        public static let brown100 = Color("Primitives/Brown/Brown-100", bundle: .module)

        /// Primitives/Brown/Brown-500
        public static let brown500 = Color("Primitives/Brown/Brown-500", bundle: .module)

        /// Primitives/Brown/Brown-600
        public static let brown600 = Color("Primitives/Brown/Brown-600", bundle: .module)
    }

    public enum Semantic {
        /// Semantic/Icon/Disabled
        public static let iconDisabled = UMCColor.Primitives.tealGrey300

        /// Semantic/Icon/Inverse
        public static let iconInverse = UMCColor.Primitives.white

        /// Semantic/Icon/Neutral-Weak-400
        public static let iconNeutralWeak400 = UMCColor.Primitives.tealGrey400

        /// Semantic/Icon/Neutral-Medium-500
        public static let iconNeutralMedium500 = UMCColor.Primitives.tealGrey500

        /// Semantic/Icon/Neutral-Strong-600
        public static let iconNeutralStrong600 = UMCColor.Primitives.tealGrey600

        /// Semantic/Icon/Neutral-Stronger-700
        public static let iconNeutralStronger700 = UMCColor.Primitives.tealGrey700

        /// Semantic/Icon/Brand-Medium-500
        public static let iconBrandMedium500 = UMCColor.Primitives.teal500

        /// Semantic/Icon/Brand-Strong-600
        public static let iconBrandStrong600 = UMCColor.Primitives.teal600

        /// Semantic/Icon/Success
        public static let iconSuccess = UMCColor.Primitives.green500

        /// Semantic/Icon/Error
        public static let iconError = UMCColor.Primitives.red500

        /// Semantic/Icon/Warning
        public static let iconWarning = UMCColor.Primitives.yellow500

        /// Semantic/Fill/Disabled/Disalbed
        public static let fillDisabled = UMCColor.Primitives.tealGrey100

        /// Semantic/Fill/Neutral/Weaker-50
        public static let fillNeutralWeaker50 = UMCColor.Primitives.tealGrey50

        /// Semantic/Fill/Neutral/Weaker-Hover(Pressed)
        public static let fillNeutralWeakerHoverPressed = UMCColor.Primitives.tealGrey100

        /// Semantic/Fill/Neutral/Weak-75
        public static let fillNeutralWeak75 = UMCColor.Primitives.tealGrey75

        /// Semantic/Fill/Neutral/Weak-Hover(Pressed)
        public static let fillNeutralWeakHoverPressed = UMCColor.Primitives.tealGrey200

        /// Semantic/Fill/Neutral/Medium-100
        public static let fillNeutralMedium100 = UMCColor.Primitives.tealGrey100

        /// Semantic/Fill/Neutral/Medium-Hover(Pressed)
        public static let fillNeutralMediumHoverPressed = UMCColor.Primitives.tealGrey200

        /// Semantic/Fill/Neutral/Strong-200
        public static let fillNeutralStrong200 = UMCColor.Primitives.tealGrey200

        /// Semantic/Fill/Neutral/Strong-Hover(Pressed)
        public static let fillNeutralStrongHoverPressed = UMCColor.Primitives.tealGrey300

        /// Semantic/Fill/Neutral/Default
        public static let fillNeutralDefault = UMCColor.Primitives.white

        /// Semantic/Fill/Neutral-Inverse/Weak-400
        public static let fillNeutralInverseWeak400 = UMCColor.Primitives.tealGrey400

        /// Semantic/Fill/Neutral-Inverse/Weak-Hover(Pressed)
        public static let fillNeutralInverseWeakHoverPressed = UMCColor.Primitives.tealGrey600

        /// Semantic/Fill/Neutral-Inverse/Medium-500
        public static let fillNeutralInverseMedium500 = UMCColor.Primitives.tealGrey500

        /// Semantic/Fill/Neutral-Inverse/Medium-Hover(Pressed)
        public static let fillNeutralInverseMediumHoverPressed = UMCColor.Primitives.tealGrey700

        /// Semantic/Fill/Neutral-Inverse/Strong-600
        public static let fillNeutralInverseStrong600 = UMCColor.Primitives.tealGrey600

        /// Semantic/Fill/Neutral-Inverse/Strong-Hover(Pressed)
        public static let fillNeutralInverseStrongHoverPressed = UMCColor.Primitives.tealGrey800

        /// Semantic/Fill/Neutral-Inverse/Stronger-700
        public static let fillNeutralInverseStronger700 = UMCColor.Primitives.tealGrey700

        /// Semantic/Fill/Neutral-Inverse/Stronger-Hover(Pressed)
        public static let fillNeutralInverseStrongerHoverPressed = UMCColor.Primitives.tealGrey500

        /// Semantic/Fill/Primary/Weaker-50
        public static let fillPrimaryWeaker50 = UMCColor.Primitives.teal50

        /// Semantic/Fill/Primary/Weaker-Hover(Pressed)
        public static let fillPrimaryWeakerHoverPressed = UMCColor.Primitives.teal100

        /// Semantic/Fill/Primary/Weak-75
        public static let fillPrimaryWeak75 = UMCColor.Primitives.teal75

        /// Semantic/Fill/Primary/Weak-Hover(Pressed)
        public static let fillPrimaryWeakHoverPressed = UMCColor.Primitives.teal200

        /// Semantic/Fill/Primary/Medium-100
        public static let fillPrimaryMedium100 = UMCColor.Primitives.teal100

        /// Semantic/Fill/Primary/Medium-Hover(Pressed)
        public static let fillPrimaryMediumHoverPressed = UMCColor.Primitives.teal200

        /// Semantic/Fill/Primary/Strong-200
        public static let fillPrimaryStrong200 = UMCColor.Primitives.teal200

        /// Semantic/Fill/Primary/Strong-Hover(Pressed)
        public static let fillPrimaryStrongHoverPressed = UMCColor.Primitives.teal300

        /// Semantic/Fill/Primary/Stronger-300
        public static let fillPrimaryStronger300 = UMCColor.Primitives.teal300

        /// Semantic/Fill/Primary/Stronger-Hover(Pressed)-400
        public static let fillPrimaryStrongerHoverPressed400 = UMCColor.Primitives.teal400

        /// Semantic/Fill/Primary-Inverse/Medium-400
        public static let fillPrimaryInverseMedium400 = UMCColor.Primitives.teal400

        /// Semantic/Fill/Primary-Inverse/Medium-Hover(Pressed)
        public static let fillPrimaryInverseMediumHoverPressed = UMCColor.Primitives.teal600

        /// Semantic/Fill/Primary-Inverse/Strong-500
        public static let fillPrimaryInverseStrong500 = UMCColor.Primitives.teal500

        /// Semantic/Fill/Primary-Inverse/Strong-Hover(Pressed)
        public static let fillPrimaryInverseStrongHoverPressed = UMCColor.Primitives.teal700

        /// Semantic/Fill/Primary-Inverse/Stronger-600
        public static let fillPrimaryInverseStronger600 = UMCColor.Primitives.teal600

        /// Semantic/Fill/Primary-Inverse/Stronger-Hover(Pressed)
        public static let fillPrimaryInverseStrongerHoverPressed = UMCColor.Primitives.teal800

        /// Semantic/Fill/Error/Weak-50
        public static let fillErrorWeak50 = UMCColor.Primitives.red50

        /// Semantic/Fill/Error/Weak-Hover(Pressed)
        public static let fillErrorWeakHoverPressed = UMCColor.Primitives.red200

        /// Semantic/Fill/Error/Medium-100
        public static let fillErrorMedium100 = UMCColor.Primitives.red100

        /// Semantic/Fill/Error/Medium-Hover(Pressed)
        public static let fillErrorMediumHoverPressed = UMCColor.Primitives.red300

        /// Semantic/Fill/Error/Strong-500
        public static let fillErrorStrong500 = UMCColor.Primitives.red500

        /// Semantic/Fill/Error/Strong-Hover(Pressed)
        public static let fillErrorStrongHoverPressed = UMCColor.Primitives.red700

        /// Semantic/Fill/Warning/Weak
        public static let fillWarningWeak = UMCColor.Primitives.yellow50

        /// Semantic/Fill/Warning/Weak-Hover(Pressed)
        public static let fillWarningWeakHoverPressed = UMCColor.Primitives.yellow200

        /// Semantic/Fill/Warning/Medium
        public static let fillWarningMedium = UMCColor.Primitives.yellow100

        /// Semantic/Fill/Warning/Medium-Hover(Pressed)
        public static let fillWarningMediumHoverPressed = UMCColor.Primitives.yellow300

        /// Semantic/Fill/Warning/Strong
        public static let fillWarningStrong = UMCColor.Primitives.yellow500

        /// Semantic/Fill/Warning/Strong-Hover(Pressed)
        public static let fillWarningStrongHoverPressed = UMCColor.Primitives.yellow700

        /// Semantic/Fill/Success/Weak
        public static let fillSuccessWeak = UMCColor.Primitives.green50

        /// Semantic/Fill/Success/Weak-Hover(Pressed)
        public static let fillSuccessWeakHoverPressed = UMCColor.Primitives.green200

        /// Semantic/Fill/Success/Medium
        public static let fillSuccessMedium = UMCColor.Primitives.green100

        /// Semantic/Fill/Success/Medium-Hover(Pressed)
        public static let fillSuccessMediumHoverPressed = UMCColor.Primitives.green300

        /// Semantic/Fill/Success/Strong
        public static let fillSuccessStrong = UMCColor.Primitives.green500

        /// Semantic/Fill/Success/Strong-Hover(Pressed)
        public static let fillSuccessStrongHoverPressed = UMCColor.Primitives.green700

        /// Semantic/Background/Default
        public static let backgroundDefault = UMCColor.Primitives.white

        /// Semantic/Background/Neutral-Weak
        public static let backgroundNeutralWeak = UMCColor.Primitives.tealGrey50

        /// Semantic/Background/Neutral-Medium
        public static let backgroundNeutralMedium = UMCColor.Primitives.tealGrey75

        /// Semantic/Background/Brand-Weak
        public static let backgroundBrandWeak = UMCColor.Primitives.teal50

        /// Semantic/Background/Brand-Medium
        public static let backgroundBrandMedium = UMCColor.Primitives.teal75

        /// Semantic/Surface/Default
        public static let surfaceDefault = UMCColor.Primitives.white

        /// Semantic/Surface/Disabled
        public static let surfaceDisabled = UMCColor.Primitives.tealGrey200

        /// Semantic/Surface/Neutral-Weak
        public static let surfaceNeutralWeak = UMCColor.Primitives.tealGrey50

        /// Semantic/Surface/Neutral-Medium
        public static let surfaceNeutralMedium = UMCColor.Primitives.tealGrey75

        /// Semantic/Surface/Neutral-Inverse
        public static let surfaceNeutralInverse = UMCColor.Primitives.tealGrey700

        /// Semantic/Surface/Brand-Weak
        public static let surfaceBrandWeak = UMCColor.Primitives.teal50

        /// Semantic/Surface/Brand-Medium
        public static let surfaceBrandMedium = UMCColor.Primitives.teal75

        /// Semantic/Surface/Brand-Inverse
        public static let surfaceBrandInverse = UMCColor.Primitives.teal500

        /// Semantic/Text/Inverse
        public static let textInverse = UMCColor.Primitives.white

        /// Semantic/Text/Disabled
        public static let textDisabled = UMCColor.Primitives.tealGrey300

        /// Semantic/Text/Placeholder
        public static let textPlaceholder = UMCColor.Primitives.tealGrey400

        /// Semantic/Text/Neutral-Weak-500
        public static let textNeutralWeak500 = UMCColor.Primitives.tealGrey500

        /// Semantic/Text/Neutral-Medium-600
        public static let textNeutralMedium600 = UMCColor.Primitives.tealGrey600

        /// Semantic/Text/Neutral-Strong-800
        public static let textNeutralStrong800 = UMCColor.Primitives.tealGrey800

        /// Semantic/Text/Neutral-Default
        public static let textNeutralDefault = UMCColor.Primitives.tealGrey900

        /// Semantic/Text/Brand-Disabled
        public static let textBrandDisabled = UMCColor.Primitives.teal300

        /// Semantic/Text/Brand-Default
        public static let textBrandDefault = UMCColor.Primitives.teal600

        /// Semantic/Text/Brand-Strong
        public static let textBrandStrong = UMCColor.Primitives.teal800

        /// Semantic/Text/Success
        public static let textSuccess = UMCColor.Primitives.green600

        /// Semantic/Text/Error
        public static let textError = UMCColor.Primitives.red500

        /// Semantic/Text/Warning
        public static let textWarning = UMCColor.Primitives.yellow600

        /// Semantic/Border/Disabled/Disalbed
        public static let borderDisabled = UMCColor.Primitives.tealGrey200

        /// Semantic/Border/Neutral/Weaker-100
        public static let borderNeutralWeaker100 = UMCColor.Primitives.tealGrey100

        /// Semantic/Border/Neutral/Weak-200
        public static let borderNeutralWeak200 = UMCColor.Primitives.tealGrey200

        /// Semantic/Border/Neutral/Medium-300
        public static let borderNeutralMedium300 = UMCColor.Primitives.tealGrey300

        /// Semantic/Border/Neutral/Strong-400
        public static let borderNeutralStrong400 = UMCColor.Primitives.tealGrey400

        /// Semantic/Border/Neutral/Stronger-600
        public static let borderNeutralStronger600 = UMCColor.Primitives.tealGrey600

        /// Semantic/Border/Neutral/Default
        public static let borderNeutralDefault = UMCColor.Primitives.white

        /// Semantic/Border/Primary/Weaker-100
        public static let borderPrimaryWeaker100 = UMCColor.Primitives.teal100

        /// Semantic/Border/Primary/Weak-200
        public static let borderPrimaryWeak200 = UMCColor.Primitives.teal200

        /// Semantic/Border/Primary/Medium-300
        public static let borderPrimaryMedium300 = UMCColor.Primitives.teal300

        /// Semantic/Border/Primary/Strong-500
        public static let borderPrimaryStrong500 = UMCColor.Primitives.teal500

        /// Semantic/Border/Error/Weaker-100
        public static let borderErrorWeaker100 = UMCColor.Primitives.red100

        /// Semantic/Border/Error/Weak-200
        public static let borderErrorWeak200 = UMCColor.Primitives.red200

        /// Semantic/Border/Error/Medium-300
        public static let borderErrorMedium300 = UMCColor.Primitives.red300

        /// Semantic/Border/Error/Strong-500
        public static let borderErrorStrong500 = UMCColor.Primitives.red500

        /// Semantic/Border/Warning/Weaker-100
        public static let borderWarningWeaker100 = UMCColor.Primitives.yellow100

        /// Semantic/Border/Warning/Weak-200
        public static let borderWarningWeak200 = UMCColor.Primitives.yellow200

        /// Semantic/Border/Warning/Medium-300
        public static let borderWarningMedium300 = UMCColor.Primitives.yellow300

        /// Semantic/Border/Warning/Strong-500
        public static let borderWarningStrong500 = UMCColor.Primitives.yellow500

        /// Semantic/Border/Success/Weaker
        public static let borderSuccessWeaker = UMCColor.Primitives.green100

        /// Semantic/Border/Success/Weak
        public static let borderSuccessWeak = UMCColor.Primitives.green200

        /// Semantic/Border/Success/Medium
        public static let borderSuccessMedium = UMCColor.Primitives.green300

        /// Semantic/Border/Success/Strong
        public static let borderSuccessStrong = UMCColor.Primitives.green500

        /// Semantic/Tag/Part/PM/Weaker
        public static let tagPartPmWeaker = UMCColor.Primitives.violet50

        /// Semantic/Tag/Part/PM/Weak
        public static let tagPartPmWeak = UMCColor.Primitives.violet100

        /// Semantic/Tag/Part/PM/Medium
        public static let tagPartPmMedium = UMCColor.Primitives.violet500

        /// Semantic/Tag/Part/PM/Strong
        public static let tagPartPmStrong = UMCColor.Primitives.violet600

        /// Semantic/Tag/Part/Design/Weaker
        public static let tagPartDesignWeaker = UMCColor.Primitives.pink50

        /// Semantic/Tag/Part/Design/Weak
        public static let tagPartDesignWeak = UMCColor.Primitives.pink100

        /// Semantic/Tag/Part/Design/Medium
        public static let tagPartDesignMedium = UMCColor.Primitives.pink500

        /// Semantic/Tag/Part/Design/Strong
        public static let tagPartDesignStrong = UMCColor.Primitives.pink600

        /// Semantic/Tag/Part/Mobile-PE/Weaker
        public static let tagPartMobilePeWeaker = UMCColor.Primitives.cobalt50

        /// Semantic/Tag/Part/Mobile-PE/Weak
        public static let tagPartMobilePeWeak = UMCColor.Primitives.cobalt100

        /// Semantic/Tag/Part/Mobile-PE/Medium
        public static let tagPartMobilePeMedium = UMCColor.Primitives.cobalt500

        /// Semantic/Tag/Part/Mobile-PE/Strong
        public static let tagPartMobilePeStrong = UMCColor.Primitives.cobalt600

        /// Semantic/Tag/Part/Web-PE/Weaker
        public static let tagPartWebPeWeaker = UMCColor.Primitives.yellow50

        /// Semantic/Tag/Part/Web-PE/Weak
        public static let tagPartWebPeWeak = UMCColor.Primitives.yellow100

        /// Semantic/Tag/Part/Web-PE/Medium
        public static let tagPartWebPeMedium = UMCColor.Primitives.yellow500

        /// Semantic/Tag/Part/Web-PE/Strong
        public static let tagPartWebPeStrong = UMCColor.Primitives.yellow600

        /// Semantic/Tag/Role/Central/Weaker
        public static let tagRoleCentralWeaker = UMCColor.Primitives.purple50

        /// Semantic/Tag/Role/Central/Weak
        public static let tagRoleCentralWeak = UMCColor.Primitives.purple100

        /// Semantic/Tag/Role/Central/Medium
        public static let tagRoleCentralMedium = UMCColor.Primitives.purple500

        /// Semantic/Tag/Role/Central/Strong
        public static let tagRoleCentralStrong = UMCColor.Primitives.purple600

        /// Semantic/Tag/Role/Chapter/Weaker
        public static let tagRoleChapterWeaker = UMCColor.Primitives.brown50

        /// Semantic/Tag/Role/Chapter/Weak
        public static let tagRoleChapterWeak = UMCColor.Primitives.brown100

        /// Semantic/Tag/Role/Chapter/Medium
        public static let tagRoleChapterMedium = UMCColor.Primitives.brown500

        /// Semantic/Tag/Role/Chapter/Strong
        public static let tagRoleChapterStrong = UMCColor.Primitives.brown600

        /// Semantic/Tag/Role/Campus/Weaker
        public static let tagRoleCampusWeaker = UMCColor.Primitives.blue50

        /// Semantic/Tag/Role/Campus/Weak
        public static let tagRoleCampusWeak = UMCColor.Primitives.blue100

        /// Semantic/Tag/Role/Campus/Medium
        public static let tagRoleCampusMedium = UMCColor.Primitives.blue500

        /// Semantic/Tag/Role/Campus/Strong
        public static let tagRoleCampusStrong = UMCColor.Primitives.blue600

        /// Semantic/Tag/Role/Challenger&Super-Admin/Weaker
        public static let tagRoleChallengerSuperAdminWeaker = UMCColor.Primitives.teal50

        /// Semantic/Tag/Role/Challenger&Super-Admin/Weak
        public static let tagRoleChallengerSuperAdminWeak = UMCColor.Primitives.teal100

        /// Semantic/Tag/Role/Challenger&Super-Admin/Medium
        public static let tagRoleChallengerSuperAdminMedium = UMCColor.Primitives.teal100

        /// Semantic/Tag/Role/Challenger&Super-Admin/Strong
        public static let tagRoleChallengerSuperAdminStrong = UMCColor.Primitives.teal600

        /// Semantic/Tag/Role/Product/Weaker
        public static let tagRoleProductWeaker = UMCColor.Primitives.tealGrey75

        /// Semantic/Tag/Role/Product/Weak
        public static let tagRoleProductWeak = UMCColor.Primitives.tealGrey100

        /// Semantic/Tag/Role/Product/Medium
        public static let tagRoleProductMedium = UMCColor.Primitives.tealGrey100

        /// Semantic/Tag/Role/Product/Strong
        public static let tagRoleProductStrong = UMCColor.Primitives.tealGrey800

        /// Semantic/Dimmed/Weak
        public static let dimmedWeak = UMCColor.Primitives.tealGrey900.opacity(0.2)

        /// Semantic/Dimmed/Medium
        public static let dimmedMedium = UMCColor.Primitives.tealGrey900.opacity(0.65)

        /// Semantic/Dimmed/Strong
        public static let dimmedStrong = UMCColor.Primitives.tealGrey900.opacity(0.85)
    }
}
