# 레포지토리 구조 (평탄화 완료)

## 현재 구조

```
messenger/
├── app/              # Flutter
├── server/           # NestJS
├── shared/           # 공유 TypeScript 패키지
├── docs/
├── scripts/
└── ...

app/lib/
└── features/
    └── chat/
        ├── screens/
        ├── widgets/
        ├── data/
        └── providers/
```

## 적용된 변경 사항

1. **루트**: apps/app → app, apps/server → server, packages/shared-server → shared
2. **Flutter**: features/*/presentation/screens → features/*/screens
3. **Flutter**: features/*/presentation/widgets → features/*/widgets
4. **설정**: pnpm-workspace, package.json, CI, README 경로 업데이트
