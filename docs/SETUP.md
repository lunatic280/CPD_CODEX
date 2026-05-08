# 실행 준비 안내

## 전제 조건

이 프로젝트는 Flutter 앱입니다. 실행하려면 Flutter SDK가 필요합니다.

현재 프로젝트에서는 `C:\flutter\bin\flutter.bat` 경로의 Flutter SDK를 확인했다.
다만 `PATH`에는 아직 등록되어 있지 않아 `flutter`만 입력하면 명령을 찾지 못한다.

남은 사용자 설정은 Windows 환경 변수 `Path`에 다음 경로를 추가하는 것이다.

```powershell
C:\flutter\bin
```

## Flutter SDK 설치 후 실행할 명령

Flutter SDK가 설치되고 `flutter` 명령이 PATH에서 동작하면 프로젝트 루트에서 다음 순서로 실행합니다.

```powershell
flutter doctor
flutter create .
flutter pub get
flutter analyze
flutter test
```

PATH 등록 전에는 다음처럼 절대 경로를 사용할 수 있습니다.

```powershell
C:\flutter\bin\flutter.bat doctor
C:\flutter\bin\flutter.bat create .
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

`flutter create .`는 누락된 Android, iOS, Windows, Linux, macOS, Web 플랫폼 스캐폴드 파일을 Flutter 도구가 공식 템플릿 기준으로 생성하도록 합니다.
이 프로젝트에서는 플랫폼 파일을 수동으로 작성하지 않습니다.

현재는 `flutter create .`, `flutter pub get`, `flutter analyze`, `flutter test`를 `C:\flutter\bin\flutter.bat` 절대 경로로 실행했고 테스트가 통과했다.

## 로컬 저장소

게시판 데이터는 서버 없이 SQLite에 저장합니다.
현재 의존성은 `pubspec.yaml`에서 `sqflite`, `path`, 테스트용 `sqflite_common_ffi`를 사용하도록 정의되어 있습니다.

## 차단 사항

Flutter SDK가 없거나 PATH에 등록되지 않은 상태에서는 다음 작업을 일반 `flutter` 명령으로 완료할 수 없습니다.

- 플랫폼 스캐폴드 생성
- 패키지 다운로드
- 정적 분석
- 테스트 실행
- 실제 앱 실행

현재 남은 설정은 `C:\flutter\bin`을 Windows `PATH`에 등록하는 것이다.
