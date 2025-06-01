# セットアップガイド

## 前提条件

### 必要なツール
- Docker & Docker Compose
- AWS CLI (設定済み)
- Terraform >= 1.0
- Python 3.11+ (ローカル開発用)

### AWS権限
ECSタスクが以下のサービスにアクセスできる必要があります：
- AWS X-Ray (トレース送信)
- CloudWatch (メトリクス・ログ)
- ECR (コンテナイメージ)

## ローカル開発

### 1. 依存関係のインストール
```bash
cd app
pip install -r requirements.txt
```

### 2. OpenTelemetryの自動計装セットアップ
```bash
opentelemetry-bootstrap -a install
```

### 3. アプリケーションの起動
```bash
# OpenTelemetryの自動計装付きで起動
opentelemetry-instrument uvicorn main:app --host 0.0.0.0 --port 8000

# または通常起動（トレースなし）
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 4. Docker Composeでの起動
```bash
# AWS認証情報を環境変数に設定
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=ap-northeast-1

# サービス起動
docker-compose up -d

# ログ確認
docker-compose logs -f
```

### 5. ローカルテストの実行
```bash
chmod +x scripts/test-local.sh
./scripts/test-local.sh
```

## AWS環境へのデプロイ

### 1. AWS認証情報の設定
```bash
aws configure
# または
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=ap-northeast-1
```

### 2. 自動デプロイスクリプトの実行
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 3. 手動デプロイ（詳細制御が必要な場合）

#### ECRリポジトリの作成とイメージプッシュ
```bash
# ECRリポジトリ作成
aws ecr create-repository --repository-name fastapi-xray-demo

# ECRログイン
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

# イメージビルド・プッシュ
docker build -f docker/Dockerfile -t fastapi-xray-demo .
docker tag fastapi-xray-demo:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/fastapi-xray-demo:latest
docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/fastapi-xray-demo:latest
```

#### Terraformでインフラ構築
```bash
cd terraform

# 初期化
terraform init

# 変数ファイル作成
cat > terraform.tfvars << EOF
aws_region = "us-west-2"
container_image = "<account-id>.dkr.ecr.us-west-2.amazonaws.com/fastapi-xray-demo:latest"
EOF

# プラン確認
terraform plan

# 適用
terraform apply
```

## 動作確認

### エンドポイントテスト
```bash
# ALBのホスト名を取得
ALB_HOSTNAME=$(cd terraform && terraform output -raw alb_hostname)

# ヘルスチェック
curl http://$ALB_HOSTNAME/health

# API呼び出し（トレース生成）
curl http://$ALB_HOSTNAME/api/users/1
curl http://$ALB_HOSTNAME/api/external
curl http://$ALB_HOSTNAME/api/database
```

### X-Rayコンソールでトレース確認
1. AWS X-Rayコンソールにアクセス
2. サービスマップでアプリケーションを確認
3. トレース一覧で詳細なトレース情報を確認

### CloudWatchログ確認
```bash
# ECSサービスのログ確認
aws logs describe-log-groups --log-group-name-prefix "/ecs/fastapi-xray-otel"

# ログストリーム確認
aws logs describe-log-streams --log-group-name "/ecs/fastapi-xray-otel/fastapi"
```

## トラブルシューティング

### よくある問題

1. **トレースがX-Rayに表示されない**
   - IAMロールの権限確認
   - ADOT Collectorの設定確認
   - ネットワーク接続確認

2. **ECSタスクが起動しない**
   - CloudWatchログでエラー確認
   - タスク定義の設定確認
   - セキュリティグループの設定確認

3. **ローカルでADOT Collectorが動作しない**
   - AWS認証情報の設定確認
   - Docker Composeの設定確認

### ログ確認コマンド
```bash
# ECSサービスログ
aws logs tail /ecs/fastapi-xray-otel/fastapi --follow

# ADOT Collectorログ
aws logs tail /ecs/fastapi-xray-otel/adot-collector --follow

# Docker Composeログ
docker-compose logs -f fastapi-app
docker-compose logs -f adot-collector
```

## カスタマイズ

### OpenTelemetryの設定変更
- `config/otel-collector-config.yaml`: Collectorの設定
- `docker/Dockerfile`: 環境変数の調整
- `app/main.py`: アプリケーション固有の計装

### Terraformの設定変更
- `terraform/variables.tf`: デフォルト値の変更
- `terraform/terraform.tfvars`: 環境固有の設定
- リソースの追加・変更は各`.tf`ファイルを編集

### スケーリング設定
```bash
# ECSサービスのタスク数変更
aws ecs update-service --cluster fastapi-xray-otel --service fastapi-xray-otel --desired-count 3
```
