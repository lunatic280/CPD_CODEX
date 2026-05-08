# CPDTestApp

Flutter와 SQLite를 사용하는 로컬 게시판 앱 예제입니다.

## 프로젝트 목표

- 서버 없이 앱 내부 SQLite 저장소만 사용합니다.
- 글 목록, 상세 보기, 작성, 수정, 삭제 흐름을 제공합니다.
- Codex 사용법을 배우는 학생이 읽기 쉽도록 단순한 구조를 유지합니다.

## 현재 실행 준비 상태

Flutter SDK는 `C:\flutter\bin\flutter.bat`에서 확인되었지만, 아직 Windows `PATH`에는 등록되어 있지 않습니다.

현재 프로젝트는 `flutter create .`로 플랫폼 스캐폴드가 생성되었고, 의존성 설치, 정적 분석, 테스트까지 통과했습니다.

PATH 설정 전에는 다음처럼 절대 경로로 Flutter를 실행할 수 있습니다.

```powershell
C:\flutter\bin\flutter.bat doctor
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

자세한 준비 절차는 [docs/SETUP.md](docs/SETUP.md)를 참고하세요.
