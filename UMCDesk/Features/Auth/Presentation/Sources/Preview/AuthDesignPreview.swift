//
//  AuthDesignPreview.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

#if DEBUG
import CoreDesignSystem
import SwiftUI

struct AuthDesignPreview: Identifiable {
    let id: String
    let title: String
    let section: Int
    let screen: AuthScreen
    let quote: String
    let author: String

    static let all: [AuthDesignPreview] = [
        .init(
            id: "625:9918", title: "로그인 방법 선택", section: 1,
            screen: .loginSelection,
            quote: "“여러분의 시간은\n한정돼 있습니다.\n다른 사람의 삶을 사느라\n낭비하지 마세요.”", author: "스티브 잡스"
        ),
        .init(
            id: "628:11639", title: "로그인 중", section: 1,
            screen: .socialLogin,
            quote: "“여러분의 시간은\n한정돼 있습니다.\n다른 사람의 삶을 사느라\n낭비하지 마세요.”", author: "스티브 잡스"
        ),
        .init(
            id: "627:10992", title: "네트워크 연결 실패", section: 1,
            screen: .offline,
            quote: "“자신을 믿으세요.\n모든 마음은 그 단단한\n현의 울림에 응답합니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "633:9894", title: "로그인 실패", section: 1,
            screen: .loginFailure,
            quote: "“우리를 흔드는 것은\n사건 자체가 아니라,\n그 사건을 바라보는\n우리의 생각입니다.”", author: "에픽테토스"
        ),
        .init(
            id: "627:11052", title: "인증정보 검증", section: 1,
            screen: .sessionChecking,
            quote: "“천 리 길도\n한 걸음부터 시작됩니다.”", author: "노자"
        ),
        .init(
            id: "628:11478", title: "로그인 후 회원 검증", section: 1,
            screen: .memberChecking,
            quote: "“먼 곳에서 벗이 찾아오니\n기쁘지 않나요?”", author: "공자"
        ),
        .init(
            id: "633:9944", title: "로그인", section: 1,
            screen: .emailLogin,
            quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”", author: "노자"
        ),
        .init(
            id: "633:11124", title: "로그인_Typed", section: 1,
            screen: .emailLogin,
            quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”", author: "노자"
        ),
        .init(
            id: "633:11665", title: "로그인_입력 불일치", section: 1,
            screen: .credentialsError,
            quote: "“자신의 일을 해내세요.\n그렇게 자신을\n더 단단하게 만드세요.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "633:11788", title: "로그인_회원정보 확인 실패", section: 1,
            screen: .memberFailure,
            quote: "“자신에게 들리는 음악에\n맞춰 걸어가세요.”", author: "헨리 데이비드 소로"
        ),
        .init(
            id: "661:13356", title: "로그인_세션 만료", section: 1,
            screen: .sessionExpired,
            quote: "“배우고 꾸준히 익히면\n즐겁지 않나요?”", author: "공자"
        ),
        .init(
            id: "633:11611", title: "로그인_비밀번호 표시", section: 1,
            screen: .emailLogin,
            quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”", author: "노자"
        ),
        .init(
            id: "633:11219", title: "로그인_Focused", section: 1,
            screen: .emailLogin,
            quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”", author: "노자"
        ),
        .init(
            id: "633:11431", title: "로그인_Typing", section: 1,
            screen: .emailLogin,
            quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”", author: "노자"
        ),
        .init(
            id: "633:12320", title: "회원가입", section: 2,
            screen: .signup,
            quote: "“일이 바라는 대로 되기를\n요구하기 보다,\n일어난 일을 받아들이세요.\n그러면 잘 지낼 수 있습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "644:12734", title: "회원가입_Focused", section: 2,
            screen: .signup,
            quote: "“일이 바라는 대로 되기를\n요구하기 보다,\n일어난 일을 받아들이세요.\n그러면 잘 지낼 수 있습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "644:12835", title: "회원가입_Typing", section: 2,
            screen: .signup,
            quote: "“일이 바라는 대로 되기를\n요구하기 보다,\n일어난 일을 받아들이세요.\n그러면 잘 지낼 수 있습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "644:12941", title: "회원가입_인증번호 발송", section: 2,
            screen: .signup,
            quote: "“큰일은\n작을 때 시작하세요.”", author: "노자"
        ),
        .init(
            id: "644:13625", title: "회원가입_학교 선택 드롭다운", section: 2,
            screen: .signup,
            quote: "“큰일은\n작을 때 시작하세요.”", author: "노자"
        ),
        .init(
            id: "648:11773", title: "회원가입_약관 동의", section: 2,
            screen: .signup,
            quote: "“모든 일에는\n두 손잡이가 있습니다.\n하나는 감당할 수 있고,\n다른 하나는 그렇지 않습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "648:12319", title: "회원가입_비밀번호", section: 2,
            screen: .signup,
            quote: "“옛 지식을 익히며\n새로운 것을 알아가면,\n다른 이의 스승이\n될 수 있습니다.”", author: "공자"
        ),
        .init(
            id: "648:12458", title: "회원가입_비밀번호 입력", section: 2,
            screen: .signup,
            quote: "“옛 지식을 익히며\n새로운 것을 알아가면,\n다른 이의 스승이\n될 수 있습니다.”", author: "공자"
        ),
        .init(
            id: "648:12201", title: "회원가입_약관 전체 동의", section: 2,
            screen: .signup,
            quote: "“모든 일에는\n두 손잡이가 있습니다.\n하나는 감당할 수 있고,\n다른 하나는 그렇지 않습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "644:13524", title: "회원가입_인증번호 Error", section: 2,
            screen: .signup,
            quote: "“큰일은\n작을 때 시작하세요.”", author: "노자"
        ),
        .init(
            id: "648:12744", title: "가입 완료", section: 2,
            screen: .signupComplete,
            quote: "“자신의 길을 고수하세요.\n다른 사람을\n흉내 내지 마세요.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "648:12782", title: "가입 완료_로그인 연결 실패", section: 2,
            screen: .signupLoginFailure,
            quote: "“삶이 넉넉하지 않더라도\n자신의 삶을 사랑하세요.”", author: "헨리 데이비드 소로"
        ),
        .init(
            id: "656:11024", title: "챌린저 인증 필요", section: 3,
            screen: .challengerIntro,
            quote: "“어떤 일이 생기면,\n그 일에 쓸 수 있는 힘이\n내 안에 무엇인지 살펴보세요.”", author: "에픽테토스"
        ),
        .init(
            id: "657:11907", title: "기존 챌린저 코드 입력", section: 3,
            screen: .challengerCode,
            quote: "“생각 없이 배우면 헛되고,\n배움 없이 생각하면\n위태롭습니다.”", author: "공자"
        ),
        .init(
            id: "658:11966", title: "기존 챌린저 코드 입력_Typed", section: 3,
            screen: .challengerCode,
            quote: "“생각 없이 배우면 헛되고,\n배움 없이 생각하면\n위태롭습니다.”", author: "공자"
        ),
        .init(
            id: "661:12473", title: "코드 인증 실패", section: 3,
            screen: .challengerCodeError,
            quote: "“자신에게 평온을 가져다줄\n수 있는 사람은\n바로 자신입니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "661:13136", title: "코드 인증 수정", section: 3,
            screen: .challengerCodeError,
            quote: "“자신에게 평온을 가져다줄\n수 있는 사람은\n바로 자신입니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "658:12056", title: "코드 등록 승인 중", section: 3,
            screen: .challengerChecking,
            quote: "“어려운 일은\n아직 쉬울 때 준비하세요.”", author: "노자"
        ),
        .init(
            id: "661:13189", title: "코드 등록 후 승인 대기", section: 3,
            screen: .challengerPending,
            quote: "“단순하게,\n더 단순하게 살아가세요.”", author: "헨리 데이비드 소로"
        ),
        .init(
            id: "661:13228", title: "기존 챌린저 인증 완료", section: 3,
            screen: .challengerComplete,
            quote: "“무슨 일이 생기더라도,\n그 안에서 도움이 되는 것을\n찾아낼 수 있습니다.”", author: "에픽테토스"
        ),
        .init(
            id: "661:13611", title: "비밀번호 찾기", section: 4,
            screen: .passwordReset,
            quote: "“아는 것은 안다고,\n모르는 것은 모른다고\n하는 것이 참된 앎입니다.”", author: "공자"
        ),
        .init(
            id: "662:13711", title: "비밀번호 찾기_인증번호 발송", section: 4,
            screen: .passwordReset,
            quote: "“아는 것은 안다고,\n모르는 것은 모른다고\n하는 것이 참된 앎입니다.”", author: "공자"
        ),
        .init(
            id: "662:13784", title: "비밀번호 찾기_Error", section: 4,
            screen: .passwordReset,
            quote: "“세 사람이 함께 걸으면,\n그 안에 나의 스승이\n있습니다.”", author: "공자"
        ),
        .init(
            id: "680:12383", title: "비밀번호 찾기_Typed", section: 4,
            screen: .passwordReset,
            quote: "“세 사람이 함께 걸으면,\n그 안에 나의 스승이\n있습니다.”", author: "공자"
        ),
        .init(
            id: "662:14135", title: "비밀번호 변경 완료", section: 4,
            screen: .passwordResetComplete,
            quote: "“남을 아는 사람은 지혜롭고,\n자신을 아는 사람은\n밝습니다.”", author: "노자"
        ),
        .init(
            id: "662:14296", title: "서비스 점검 중", section: 5,
            screen: .maintenance,
            quote: "“자신이 하는 일을 좋아하세요.\n그러면 최선을 다하게 됩니다.”", author: "캐서린 존슨"
        ),
        .init(
            id: "662:14339", title: "업데이트 공지", section: 5,
            screen: .updateAvailable,
            quote: "“혼자서는 할 수 있는 일이\n적지만, 함께라면 많은 일을\n할 수 있습니다.”", author: "헬렌 켈러"
        ),
        .init(
            id: "663:14664", title: "업데이트 실패", section: 5,
            screen: .updateDownloadError,
            quote: "“친구란 내가 진솔해질 수\n있는 사람입니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "663:14863", title: "업데이트 파일 확인 실패", section: 5,
            screen: .updateVerificationError,
            quote: "“잘못하고도 고치지 않는 것,\n그것이 진짜 잘못입니다.”", author: "공자"
        ),
        .init(
            id: "663:14905", title: "업데이트 설치 실패", section: 5,
            screen: .updateInstallationError,
            quote: "“자신의 삶에 만족할 줄\n아는 사람이 부유합니다.”", author: "노자"
        ),
        .init(
            id: "662:14566", title: "업데이트 중", section: 5,
            screen: .updateDownloading,
            quote: "“남을 이기는 사람은 강하고,\n자신을 이기는 사람은\n더 강합니다.”", author: "노자"
        ),
        .init(
            id: "680:12173", title: "파일 확인 중", section: 5,
            screen: .updateVerifying,
            quote: "“열정 없이 이루어진\n위대한 일은 없습니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "680:12295", title: "설치 중", section: 5,
            screen: .updateInstalling,
            quote: "“아는 사람은 좋아하는\n사람만 못하고,\n좋아하는 사람은 즐기는\n사람만 못합니다.”", author: "공자"
        ),
        .init(
            id: "680:12337", title: "설치 완료", section: 5,
            screen: .updateComplete,
            quote: "“배움에 힘쓰는 사람은\n날마다 지식을 더해갑니다.”", author: "노자"
        ),
        .init(
            id: "680:12232", title: "업데이트 준비 완료", section: 5,
            screen: .updateReady,
            quote: "“우리가 깨어 있어야\n새로운 날도 밝아옵니다.”", author: "헨리 데이비드 소로"
        ),
        .init(
            id: "663:15048", title: "로그아웃 확인", section: 6,
            screen: .logoutConfirmation,
            quote: "“결국 가장 소중한 것은\n자기 마음의 온전함입니다.”", author: "랠프 월도 에머슨"
        ),
        .init(
            id: "663:15095", title: "회원 탈퇴 확인", section: 6,
            screen: .withdrawalConfirmation,
            quote: "“꿈을 향해 자신 있게\n나아가고 상상한 삶을\n살고자 노력하면,\n뜻밖의 성공을 만나게 됩니다.”", author: "헨리 데이비드 소로"
        ),
    ]

    @MainActor
    func makeViewModel() -> AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.screen = screen
        viewModel.quoteOverride = quote
        viewModel.authorOverride = author
        let form = viewModel.form
        switch id {
        case "633:11219", "644:12734":
            form.initialFocus = .email
        case "633:11431", "644:12835":
            form.email = "example@example.com"
            form.initialFocus = .email
        case "633:11124", "633:11611", "633:11665":
            form.email = "example@example.com"
            form.password = "12345678"
            form.showsPassword = id == "633:11611"
        case "644:12941", "644:13524":
            form.name = "김유엠"
            form.nickname = "유엠"
            form.email = "example@example.com"
            form.emailVerification = id == "644:13524" ? .invalid : .sent
            form.verificationCode = id == "644:13524" ? "123456" : ""
        case "644:13625", "648:12319", "648:12458", "648:11773", "648:12201":
            form.name = "김유엠"
            form.nickname = "유엠"
            form.email = "example@example.com"
            form.emailVerification = .verified
            form.showsSchoolPicker = id == "644:13625"
            if id != "644:13625" { form.school = "가천대학교" }
            if id != "644:13625" && id != "648:12319" {
                form.password = "password1!"
                form.passwordConfirmation = "password1!"
            }
            form.agreesToService = id == "648:11773" || id == "648:12201"
            form.agreesToPrivacy = id == "648:12201"
        case "658:11966", "661:12473", "661:13136":
            form.challengerCode = "123456"
            form.initialFocus = id == "661:13136" ? .challengerCode : nil
        case "662:13711":
            form.email = "example@example.com"
            form.emailVerification = .sent
        case "680:12383", "662:13784":
            form.email = "example@example.com"
            form.emailVerification = .verified
            form.password = "password1!"
            form.passwordConfirmation = id == "662:13784" ? "different1!" : "password1!"
            form.showsPasswordError = id == "662:13784"
        case "662:14566":
            viewModel.downloadProgress = 0.42
        default:
            break
        }
        return viewModel
    }
}

struct AuthPreviewMenu: View {
    @Binding var viewModel: AuthViewModel
    private let sections = [
        "로그인", "회원가입", "챌린저 인증", "비밀번호 변경", "시스템", "계정 관리",
    ]

    var body: some View {
        Menu("디자인 미리보기", systemImage: "rectangle.on.rectangle") {
            ForEach(1...6, id: \.self) { section in
                Menu(sections[section - 1]) {
                    ForEach(AuthDesignPreview.all.filter { $0.section == section }) { preview in
                        Button(preview.title) { viewModel = preview.makeViewModel() }
                    }
                }
            }
        }
        .help("Figma 로그인·회원가입 섹션의 화면 상태 보기")
    }
}

struct AuthPreviewSchool: Identifiable {
    let label: String
    let name: String
    var id: String { name }

    static let all: [AuthPreviewSchool] = [
        .init(label: "가천대", name: "가천대학교"),
        .init(label: "가톨릭대", name: "가톨릭대학교"),
        .init(label: "단국대", name: "단국대학교"),
        .init(label: "덕성여대", name: "덕성여자대학교"),
        .init(label: "동국대", name: "동국대학교"),
        .init(label: "동덕여대", name: "동덕여자대학교"),
        .init(label: "동양미래대", name: "동양미래대학교"),
        .init(label: "서경대", name: "서경대학교"),
        .init(label: "서울여대", name: "서울여자대학교"),
        .init(label: "성신여대", name: "성신여자대학교"),
    ]
}

#Preview("로그인 방법 선택") {
    AuthView().frame(width: 1440, height: 908)
}

#Preview("회원가입") {
    AuthView(viewModel: AuthDesignPreview.all.first { $0.id == "648:12201" }!.makeViewModel())
        .frame(width: 1440, height: 908)
}

#Preview("챌린저 인증") {
    AuthView(viewModel: AuthDesignPreview.all.first { $0.id == "661:13228" }!.makeViewModel())
        .frame(width: 1440, height: 908)
}

#Preview("비밀번호 변경") {
    AuthView(viewModel: AuthDesignPreview.all.first { $0.id == "680:12383" }!.makeViewModel())
        .frame(width: 1440, height: 908)
}

#Preview("업데이트") {
    AuthView(viewModel: AuthDesignPreview.all.first { $0.id == "662:14566" }!.makeViewModel())
        .frame(width: 1440, height: 908)
}

#Preview("계정 관리") {
    AuthView(viewModel: AuthDesignPreview.all.first { $0.id == "663:15095" }!.makeViewModel())
        .frame(width: 1440, height: 908)
}
#endif

