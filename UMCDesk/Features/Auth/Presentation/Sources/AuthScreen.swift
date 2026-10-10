//
//  AuthScreen.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import Foundation

/// Presentation-only destinations; no authentication or account mutations are performed.
enum AuthScreen: String, CaseIterable, Identifiable {
    case loginSelection
    case socialLogin
    case offline
    case loginFailure
    case sessionChecking
    case memberChecking
    case emailLogin
    case credentialsError
    case memberFailure
    case sessionExpired
    case signup
    case signupComplete
    case signupLoginFailure
    case challengerIntro
    case challengerCode
    case challengerCodeError
    case challengerChecking
    case challengerPending
    case challengerComplete
    case passwordReset
    case passwordResetComplete
    case maintenance
    case updateAvailable
    case updateDownloading
    case updateVerifying
    case updateReady
    case updateInstalling
    case updateComplete
    case updateDownloadError
    case updateVerificationError
    case updateInstallationError
    case logoutConfirmation
    case withdrawalConfirmation

    var id: String { rawValue }

    var contentWidth: CGFloat {
        switch self {
        case .signup, .passwordReset: 652
        default: 500
        }
    }

    var updateStep: Int? {
        switch self {
        case .updateDownloading: 1
        case .updateVerifying: 2
        case .updateReady: 3
        case .updateInstalling: 4
        case .updateComplete: 5
        default: nil
        }
    }

    var copy: AuthScreenCopy {
        switch self {
        case .loginSelection:
            AuthScreenCopy(
                title: "UMC에 오신 것을 환영해요",
                subtitle: "함께 만들고, 함께 성장하는 UMC.\n활동과 프로젝트를 이어서 시작하세요.",
                quote: "“여러분의 시간은\n한정돼 있습니다.\n다른 사람의 삶을 사느라\n낭비하지 마세요.”",
                author: "스티브 잡스",
                category: "ACCOUNT / 로그인"
            )
        case .socialLogin:
            AuthScreenCopy(
                title: "UMC에 오신 것을 환영해요",
                subtitle: "함께 만들고, 함께 성장하는 UMC.\n활동과 프로젝트를 이어서 시작하세요.",
                quote: "“여러분의 시간은\n한정돼 있습니다.\n다른 사람의 삶을 사느라\n낭비하지 마세요.”",
                author: "스티브 잡스",
                category: "ACCOUNT / 로그인"
            )
        case .offline:
            AuthScreenCopy(
                title: "인터넷 연결을 확인해 주세요",
                subtitle: "인터넷에 연결한 뒤 다시 시도해 주세요.\n로그인 정보는 그대로 유지돼요.",
                quote: "“자신을 믿으세요.\n모든 마음은 그 단단한\n현의 울림에 응답합니다.”",
                author: "랠프 월도 에머슨",
                category: "ACCOUNT / 로그인",
                icon: "offline"
            )
        case .loginFailure:
            AuthScreenCopy(
                title: "로그인을 완료하지 못했어요",
                subtitle: "선택한 로그인 서비스의 인증을 확인하지 못했어요.\n잠시 후 다시 시도하거나 다른 방법을 선택해주세요.",
                quote: "“우리를 흔드는 것은\n사건 자체가 아니라,\n그 사건을 바라보는\n우리의 생각입니다.”",
                author: "에픽테토스",
                category: "ACCOUNT / 로그인",
                icon: "login-failure"
            )
        case .sessionChecking:
            AuthScreenCopy(
                title: "로그인 상태를 확인하고 있어요",
                subtitle: "안전하게 시작할 수 있도록\n로그인 정보와 UMC 회원 정보를 확인해요.",
                quote: "“천 리 길도\n한 걸음부터 시작됩니다.”",
                author: "노자",
                category: "ACCOUNT / 로그인"
            )
        case .memberChecking:
            AuthScreenCopy(
                title: "UMC 회원 정보를 확인해요",
                subtitle: "로그인한 계정의 UMC 인증 상태를 확인해요.\n확인이 끝날 때까지 잠시 기다려주세요.",
                quote: "“먼 곳에서 벗이 찾아오니\n기쁘지 않나요?”",
                author: "공자",
                category: "ACCOUNT / 로그인"
            )
        case .emailLogin:
            AuthScreenCopy(
                title: "UMC 계정으로 로그인",
                subtitle: "등록한 이메일과 비밀번호를 입력해 주세요.",
                quote: "“아름드리나무도\n아주 작은 싹에서\n자라났습니다.”",
                author: "노자",
                category: "ACCOUNT / 로그인"
            )
        case .credentialsError:
            AuthScreenCopy(
                title: "UMC 계정으로 로그인",
                subtitle: "등록한 이메일과 비밀번호를 입력해 주세요.",
                quote: "“자신의 일을 해내세요.\n그렇게 자신을\n더 단단하게 만드세요.”",
                author: "랠프 월도 에머슨",
                category: "ACCOUNT / 로그인"
            )
        case .memberFailure:
            AuthScreenCopy(
                title: "회원 정보를 확인하지 못했어요",
                subtitle: "계정 로그인은 완료했지만\nUMC 회원 정보를 불러오지 못했어요.",
                quote: "“자신에게 들리는 음악에\n맞춰 걸어가세요.”",
                author: "헨리 데이비드 소로",
                category: "ACCOUNT / 로그인",
                icon: "member-failure"
            )
        case .sessionExpired:
            AuthScreenCopy(
                title: "다시 로그인해 주세요",
                subtitle: "로그인 시간이 만료되었어요.\n사용하던 계정으로 다시 시작해 주세요.",
                quote: "“배우고 꾸준히 익히면\n즐겁지 않나요?”",
                author: "공자",
                category: "ACCOUNT / 로그인",
                icon: "session-expired"
            )
        case .signup:
            AuthScreenCopy(
                title: "회원가입",
                subtitle: "UMC 활동에 사용할 정보를 입력해 주세요.",
                quote: "“일이 바라는 대로 되기를\n요구하기 보다,\n일어난 일을 받아들이세요.\n그러면 잘 지낼 수 있습니다.”",
                author: "에픽테토스",
                category: "ACCOUNT / 회원가입"
            )
        case .signupComplete:
            AuthScreenCopy(
                title: "가입을 마쳤어요",
                subtitle: "운영진의 승인이 완료되면 UMC를 이용할 수 있어요.",
                quote: "“자신의 길을 고수하세요.\n다른 사람을\n흉내 내지 마세요.”",
                author: "랠프 월도 에머슨",
                category: "ACCOUNT / 회원가입",
                icon: "signup-complete"
            )
        case .signupLoginFailure:
            AuthScreenCopy(
                title: "가입을 마쳤어요",
                subtitle: "로그인 연결을 마치지 못했어요.\n가입한 계정으로 다시 로그인해 주세요.",
                quote: "“삶이 넉넉하지 않더라도\n자신의 삶을 사랑하세요.”",
                author: "헨리 데이비드 소로",
                category: "ACCOUNT / 회원가입",
                icon: "signup-complete"
            )
        case .challengerIntro:
            AuthScreenCopy(
                title: "챌린저 정보를 연결해요",
                subtitle: "로그인은 완료됐지만\n등록된 UMC 챌린저 정보를 찾지 못했어요",
                quote: "“어떤 일이 생기면,\n그 일에 쓸 수 있는 힘이\n내 안에 무엇인지 살펴보세요.”",
                author: "에픽테토스",
                category: "ACCOUNT / 챌린저 인증"
            )
        case .challengerCode:
            AuthScreenCopy(
                title: "챌린저 코드를 입력해 주세요",
                subtitle: "운영진에게 발급받은\n영문, 숫자 6자리 코드를 입력해 주세요.",
                quote: "“생각 없이 배우면 헛되고,\n배움 없이 생각하면\n위태롭습니다.”",
                author: "공자",
                category: "ACCOUNT / 챌린저 인증"
            )
        case .challengerCodeError:
            AuthScreenCopy(
                title: "코드를 다시 확인해 주세요",
                subtitle: "",
                quote: "“자신에게 평온을 가져다줄\n수 있는 사람은\n바로 자신입니다.”",
                author: "랠프 월도 에머슨",
                category: "ACCOUNT / 챌린저 인증"
            )
        case .challengerChecking:
            AuthScreenCopy(
                title: "챌린저 인증을 확인하고 있어요",
                subtitle: "챌린저 코드와 회원 정보를 확인해요.\n확인이 끝날 때까지 잠시 기다려 주세요.",
                quote: "“어려운 일은\n아직 쉬울 때 준비하세요.”",
                author: "노자",
                category: "ACCOUNT / 챌린저 인증"
            )
        case .challengerPending:
            AuthScreenCopy(
                title: "코드 등록을 마쳤어요",
                subtitle: "운영진의 최종 승인을 기다리고 있어요.\n승인이 완료되면 UMC를 이용할 수 있어요.",
                quote: "“단순하게,\n더 단순하게 살아가세요.”",
                author: "헨리 데이비드 소로",
                category: "ACCOUNT / 챌린저 인증",
                icon: "challenger-pending"
            )
        case .challengerComplete:
            AuthScreenCopy(
                title: "챌린저 인증을 마쳤어요",
                subtitle: "기존 챌린저로 인증되었어요.\n이제 UMC 서비스를 이용할 수 있어요.",
                quote: "“무슨 일이 생기더라도,\n그 안에서 도움이 되는 것을\n찾아낼 수 있습니다.”",
                author: "에픽테토스",
                category: "ACCOUNT / 챌린저 인증"
            )
        case .passwordReset:
            AuthScreenCopy(
                title: "비밀번호 찾기",
                subtitle: "이메일을 인증하고 새 비밀번호를 설정해 주세요.",
                quote: "“아는 것은 안다고,\n모르는 것은 모른다고\n하는 것이 참된 앎입니다.”",
                author: "공자",
                category: "ACCOUNT / 비밀번호 찾기"
            )
        case .passwordResetComplete:
            AuthScreenCopy(
                title: "비밀번호를 변경했어요",
                subtitle: "변경된 비밀번호로 다시 로그인해 주세요.",
                quote: "“남을 아는 사람은 지혜롭고,\n자신을 아는 사람은\n밝습니다.”",
                author: "노자",
                category: "ACCOUNT / 비밀번호 찾기",
                icon: "password-complete"
            )
        case .maintenance:
            AuthScreenCopy(
                title: "잠시 서비스를 점검하고 있어요",
                subtitle: "안정적인 서비스를 위해 점검하고 있어요.\n점검이 끝나면 다시 이용할 수 있어요.",
                quote: "“자신이 하는 일을 좋아하세요.\n그러면 최선을 다하게 됩니다.”",
                author: "캐서린 존슨",
                category: "SYSTEM / 점검",
                icon: "maintenance"
            )
        case .updateAvailable:
            AuthScreenCopy(
                title: "새로운 버전이 있어요",
                subtitle: "앱에서 새 버전을 다운로드 하고 설치할 수 있어요.",
                quote: "“혼자서는 할 수 있는 일이\n적지만, 함께라면 많은 일을\n할 수 있습니다.”",
                author: "헬렌 켈러",
                category: "SYSTEM / 업데이트",
                icon: "update"
            )
        case .updateDownloading:
            AuthScreenCopy(
                title: "새 버전을 다운로드하고 있어요",
                subtitle: "다운로드가 끝나면 업데이트 파일을 확인할게요.",
                quote: "“남을 이기는 사람은 강하고,\n자신을 이기는 사람은\n더 강합니다.”",
                author: "노자",
                category: "SYSTEM / 업데이트"
            )
        case .updateVerifying:
            AuthScreenCopy(
                title: "업데이트 파일을 확인하고 있어요",
                subtitle: "다운로드한 파일을 안전하게 설치할 수 있는지 확인할게요.",
                quote: "“열정 없이 이루어진\n위대한 일은 없습니다.”",
                author: "랠프 월도 에머슨",
                category: "SYSTEM / 업데이트"
            )
        case .updateReady:
            AuthScreenCopy(
                title: "업데이트 준비가 끝났어요",
                subtitle: "설치를 진행하고 앱을 다시 시작하면 새 버전이 적용돼요.",
                quote: "“우리가 깨어 있어야\n새로운 날도 밝아옵니다.”",
                author: "헨리 데이비드 소로",
                category: "SYSTEM / 업데이트"
            )
        case .updateInstalling:
            AuthScreenCopy(
                title: "새 버전을 설치하고 있어요",
                subtitle: "설치가 끝날 때까지 앱을 종료하지 말고 잠시 기다려 주세요.",
                quote: "“아는 사람은 좋아하는\n사람만 못하고,\n좋아하는 사람은 즐기는\n사람만 못합니다.”",
                author: "공자",
                category: "SYSTEM / 업데이트"
            )
        case .updateComplete:
            AuthScreenCopy(
                title: "업데이트를 완료했어요",
                subtitle: "앱을 다시 시작하면 새 버전으로 이용할 수 있어요.",
                quote: "“배움에 힘쓰는 사람은\n날마다 지식을 더해갑니다.”",
                author: "노자",
                category: "SYSTEM / 업데이트"
            )
        case .updateDownloadError:
            AuthScreenCopy(
                title: "다운로드를 완료하지 못했어요",
                subtitle: "인터넷 연결을 확인한 뒤 다시 시도해 주세요.",
                quote: "“친구란 내가 진솔해질 수\n있는 사람입니다.”",
                author: "랠프 월도 에머슨",
                category: "SYSTEM / 업데이트",
                icon: "update-error"
            )
        case .updateVerificationError:
            AuthScreenCopy(
                title: "업데이트 파일을 확인하지 못했어요",
                subtitle: "설치를 진행하지 않았어요. 파일을 다시 다운로드해 주세요.",
                quote: "“잘못하고도 고치지 않는 것,\n그것이 진짜 잘못입니다.”",
                author: "공자",
                category: "SYSTEM / 업데이트",
                icon: "update-error"
            )
        case .updateInstallationError:
            AuthScreenCopy(
                title: "설치를 완료하지 못했어요",
                subtitle: "앱을 다시 시작한 뒤 업데이트 상태를 확인해 주세요.",
                quote: "“자신의 삶에 만족할 줄\n아는 사람이 부유합니다.”",
                author: "노자",
                category: "SYSTEM / 업데이트",
                icon: "update-error"
            )
        case .logoutConfirmation:
            AuthScreenCopy(
                title: "로그아웃할까요?",
                subtitle: "현재 계정에서 로그아웃해요.\n계속 이용하려면 다시 로그인해 주세요.",
                quote: "“결국 가장 소중한 것은\n자기 마음의 온전함입니다.”",
                author: "랠프 월도 에머슨",
                category: "ACCOUNT / 계정 관리",
                icon: "logout"
            )
        case .withdrawalConfirmation:
            AuthScreenCopy(
                title: "회원 탈퇴를 진행할까요?",
                subtitle: "",
                quote: "“꿈을 향해 자신 있게\n나아가고 상상한 삶을\n살고자 노력하면,\n뜻밖의 성공을 만나게 됩니다.”",
                author: "헨리 데이비드 소로",
                category: "ACCOUNT / 계정 관리",
                icon: "withdrawal"
            )
        }
    }
}

struct AuthScreenCopy {
    let title: String
    let subtitle: String
    let quote: String
    let author: String
    let category: String
    var icon: String? = nil
}
