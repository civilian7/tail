# tail

Windows용 실시간 파일 모니터링 도구입니다. Unix의 `tail -f` 명령어와 유사하게 동작하며, 로그 파일 등을 실시간으로 추적할 수 있습니다.

## 기능

- 파일의 마지막 N줄 출력
- 파일 변경 실시간 감지 및 출력
- 파일 삭제/이동 감지
- 로그 로테이션(파일 truncate) 대응
- Ctrl+C로 안전하게 종료

## 빌드 방법

### 요구사항

- Delphi 10.x 이상 (또는 RAD Studio)

### 빌드

1. `tail.dpr` 파일을 Delphi IDE에서 열기
2. **Project > Build** (또는 Shift+F9)
3. `tail.exe`가 생성됨

### 명령줄 빌드

```batch
msbuild tail.dpr /p:Config=Release /p:Platform=Win32
```

또는 Delphi 명령줄 컴파일러 사용:

```batch
dcc32 tail.dpr
```

## 사용법

```
tail [options] <filename>
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-n <lines>` | 처음에 표시할 줄 수 | 10 |
| `-i <ms>` | 폴링 간격 (밀리초) | 100 |
| `-h, --help` | 도움말 표시 | - |

### 예제

```batch
:: 기본 사용 (마지막 10줄 표시 후 실시간 추적)
tail mylog.txt

:: 마지막 20줄 표시
tail -n 20 C:\logs\app.log

:: 폴링 간격을 500ms로 설정 (CPU 사용량 감소)
tail -i 500 mylog.txt

:: 마지막 50줄, 1초 간격으로 모니터링
tail -n 50 -i 1000 C:\logs\debug.log
```

### 동작

1. 프로그램 시작 시 파일의 마지막 N줄을 출력합니다
2. 이후 파일에 새로운 내용이 추가되면 실시간으로 콘솔에 출력합니다
3. 파일이 truncate되면 (로그 로테이션 등) 처음부터 다시 읽습니다
4. Ctrl+C를 누르면 안전하게 종료됩니다

## 라이선스

MIT License
