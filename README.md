# FastAPI X-Ray with OpenTelemetry

ECS上のFastAPIアプリケーションにX-Ray + OpenTelemetryによる自動計装トレースを導入（Terraform構築 + GitHub Actions CI/CD）

## 🎯 概要

このプロジェクトは、ECS Fargate上で稼働するFastAPIアプリケーションに対して、OpenTelemetryを使用した自動計装によるトレース機能を導入し、AWS X-Rayにトレース情報を送信する完全なソリューションを提供します。

**主な特徴:**
- ✅ **完全自動化**: GitHub Actions CI/CDによる自動ビルド・デプロイ
- ✅ **最小限のコード変更**: OpenTelemetry自動計装
- ✅ **セキュア認証**: OIDC連携によるAWS認証
- ✅ **最適化ビルド**: uvパッケージマネージャー + multi-stage Docker build
- ✅ **Infrastructure as Code**: Terraformによる完全なインフラ管理

## 🏗️ アーキテクチャ

### アプリケーション層
- **FastAPI**: 高性能Webアプリケーションフレームワーク
- **OpenTelemetry**: 自動計装によるトレース収集（コード変更最小限）
- **uv**: 高速Pythonパッケージマネージャー

### インフラストラクチャ層
- **ECS Fargate**: サーバーレスコンテナ実行環境
- **Application Load Balancer**: 高可用性ロードバランサー
- **ECR**: プライベートDockerレジストリ
- **VPC**: セキュアなネットワーク環境

### 監視・トレーシング層
- **AWS Distro for OpenTelemetry Collector (ADOT)**: サイドカーコンテナとしてトレースデータを収集・転送
- **AWS X-Ray**: 分散トレーシングの可視化・分析
- **CloudWatch**: ログ集約とモニタリング
- **SSM Parameter Store**: ADOT Collector設定管理

### CI/CD層
- **GitHub Actions**: 自動ビルド・テスト・デプロイ
- **OIDC認証**: セキュアなAWS認証（長期キー不要）
- **Multi-stage Docker Build**: 最適化されたコンテナイメージ

## 📁 ディレクトリ構造

```
fastapi-x-ray-with-otel/
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions CI/CDパイプライン
├── app/
│   ├── main.py                 # FastAPIアプリケーション
│   └── requirements.txt        # Python依存関係
├── terraform/
│   ├── main.tf                 # メインTerraform設定
│   ├── variables.tf            # 変数定義
│   ├── outputs.tf              # 出力値
│   ├── iam.tf                  # IAMロール・ポリシー（OIDC含む）
│   ├── ecs.tf                  # ECSクラスター・サービス・タスク定義
│   ├── alb.tf                  # Application Load Balancer
│   └── ssm.tf                  # SSM Parameter Store
├── docker/
│   └── Dockerfile              # Multi-stage Docker build
├── config/
│   └── otel-collector-config.yaml  # ADOT Collector設定
├── scripts/
│   ├── deploy.sh               # デプロイスクリプト
│   ├── test-local.sh           # ローカルテストスクリプト
│   └── setup-github-secrets.sh # GitHubシークレット設定
├── docs/
│   ├── AWS_SETUP.md            # AWS認証設定ガイド
│   ├── CICD_SETUP.md           # CI/CD設定ガイド
│   ├── IAM_PERMISSIONS.md      # IAM権限詳細ガイド
│   └── SETUP.md                # セットアップガイド
├── docker-compose.yml          # ローカル開発環境
└── README.md                   # このファイル
```

## 🚀 クイックスタート

### 前提条件

- **AWS CLI**: 設定済み（`aws configure --profile my-dev-profile`）
- **Docker**: コンテナビルド用
- **Terraform**: インフラ構築用
- **GitHub CLI**: シークレット設定用（`gh auth login`）
- **Python 3.11+**: ローカル開発用
- **uv**: Pythonパッケージマネージャー

### 1. リポジトリクローン

```bash
git clone https://github.com/keylium/fastapi-x-ray-with-otel.git
cd fastapi-x-ray-with-otel
```

### 2. AWS認証設定

```bash
# AWS プロファイル設定
aws configure --profile my-dev-profile
export AWS_PROFILE=my-dev-profile

# 認証確認
aws sts get-caller-identity
```

### 3. インフラ構築

```bash
cd terraform

# Terraform初期化
terraform init

# インフラ構築
terraform plan
terraform apply
```

### 4. GitHub Actions設定

```bash
# GitHubシークレット自動設定
./scripts/setup-github-secrets.sh

# または手動設定
ROLE_ARN=$(cd terraform && terraform output -raw github_actions_role_arn)
gh secret set AWS_ROLE_TO_ASSUME --body "$ROLE_ARN" --repo "keylium/fastapi-x-ray-with-otel"
```

### 5. アプリケーションデプロイ

```bash
# 手動デプロイ（初回のみ）
./scripts/deploy.sh

# または GitHub Actions経由（mainブランチプッシュ時自動実行）
git push origin main
```

## 🧪 ローカル開発

### ローカルテスト実行

```bash
# Docker Composeでローカル環境起動
./scripts/test-local.sh

# 手動でのローカル環境起動
docker-compose up -d

# アプリケーションテスト
curl http://localhost:8000/
curl http://localhost:8000/api/users/123
curl http://localhost:8000/api/database
```

### 開発環境の特徴

- **ホットリロード**: FastAPIの自動リロード機能
- **ADOT Collector**: ローカルでのトレース収集テスト
- **環境分離**: Docker Composeによる完全な環境分離

## 🔄 CI/CD パイプライン

### GitHub Actions ワークフロー

**トリガー:**
- `main`ブランチへのプッシュ → 自動ビルド・デプロイ
- プルリクエスト → テストのみ実行

**ジョブ構成:**

1. **Test Job**
   - uvパッケージマネージャーセットアップ
   - Python 3.11環境構築
   - 仮想環境での依存関係インストール
   - ローカルテスト実行

2. **Build and Deploy Job** (mainブランチのみ)
   - AWS OIDC認証
   - ECRログイン・リポジトリ管理
   - Multi-stage Dockerビルド
   - ECRイメージプッシュ
   - ECSサービス自動更新

### セキュリティ機能

- **OIDC認証**: 長期的なAWSアクセスキー不要
- **最小権限**: IAMロールは必要最小限の権限のみ
- **リポジトリ制限**: 特定リポジトリからのみアクセス可能

## 🐳 Docker最適化

### Multi-stage Build

```dockerfile
# deps stage: uvで依存関係をcompile
FROM python:3.11-slim AS deps
RUN uv pip compile requirements.txt --output-file requirements-compiled.txt

# prod stage: pipで高速install
FROM python:3.11-slim AS prod
COPY --from=deps /app/requirements-compiled.txt .
RUN pip install --no-cache-dir -r requirements-compiled.txt
```

### 最適化効果

- ✅ **ビルド時間短縮**: uvによる高速依存関係解決
- ✅ **イメージサイズ削減**: 不要なビルドツールを除外
- ✅ **セキュリティ向上**: 本番環境にビルドツール不要
- ✅ **キャッシュ効率**: レイヤーキャッシュの最適化

## 📊 監視・トレーシング

### AWS X-Ray トレーシング

**自動計装対象:**
- HTTPリクエスト/レスポンス
- データベースクエリ
- 外部API呼び出し
- 内部サービス間通信

**X-Rayコンソール:**
```
https://ap-northeast-1.console.aws.amazon.com/xray/home
```

### CloudWatch ログ

**ログ確認:**
```bash
# ECSタスクログ確認
aws logs describe-log-groups --log-group-name-prefix "/ecs/fastapi-xray-otel"

# リアルタイムログ監視
aws logs tail /ecs/fastapi-xray-otel-fastapi-app --follow
```

## 🔧 設定カスタマイズ

### 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `OTEL_SERVICE_NAME` | サービス名 | `fastapi-xray-demo` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP エンドポイント | `http://localhost:4317` |
| `AWS_REGION` | AWSリージョン | `ap-northeast-1` |

### Terraform変数

```hcl
# terraform/terraform.tfvars
project_name = "fastapi-xray-otel"
aws_region   = "ap-northeast-1"
vpc_cidr     = "10.1.0.0/16"
```

## 🛠️ トラブルシューティング

### よくある問題

1. **GitHub Actions認証エラー**
   ```
   Error: Credentials could not be loaded
   ```
   **解決策**: GitHubシークレット`AWS_ROLE_TO_ASSUME`を設定

2. **ECSタスク起動失敗**
   ```
   CannotPullContainerError
   ```
   **解決策**: ECRリポジトリの存在確認、IAM権限確認

3. **X-Rayトレース表示されない**
   **解決策**: ADOT Collector設定確認、IAMロール権限確認

### デバッグコマンド

```bash
# ECSタスク状態確認
aws ecs describe-tasks --cluster fastapi-xray-otel --tasks $(aws ecs list-tasks --cluster fastapi-xray-otel --query 'taskArns[0]' --output text)

# CloudWatchログ確認
aws logs tail /ecs/fastapi-xray-otel-fastapi-app --follow

# X-Rayトレース確認
aws xray get-trace-summaries --time-range-type TimeRangeByStartTime --start-time 2024-01-01T00:00:00Z --end-time 2024-12-31T23:59:59Z
```

## 📚 詳細ドキュメント

- [AWS認証設定ガイド](docs/AWS_SETUP.md)
- [CI/CD設定ガイド](docs/CICD_SETUP.md)
- [IAM権限詳細ガイド](docs/IAM_PERMISSIONS.md)
- [セットアップガイド](docs/SETUP.md)

## 🤝 コントリビューション

1. フォークしてブランチ作成
2. 変更を実装
3. テスト実行確認
4. プルリクエスト作成

## 📄 ライセンス

MIT License

## 🏷️ タグ

`FastAPI` `OpenTelemetry` `AWS X-Ray` `ECS` `Fargate` `Terraform` `GitHub Actions` `CI/CD` `Docker` `Multi-stage Build` `uv` `OIDC` `Infrastructure as Code` `Distributed Tracing` `Monitoring` `Observability`
