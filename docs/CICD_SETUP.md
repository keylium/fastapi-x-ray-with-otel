# CI/CD セットアップガイド

## GitHub Actions CI/CD パイプライン

このプロジェクトには、mainブランチへのプッシュ時に自動的にECRイメージをビルド・プッシュするGitHub Actions CI/CDパイプラインが含まれています。

## 前提条件

### 1. AWS IAM ロールの作成（OIDC連携用）

GitHub ActionsからAWSリソースにアクセスするため、OIDC（OpenID Connect）を使用したIAMロールを作成する必要があります。

#### IAMロールの作成手順

1. **アカウントIDの取得**
```bash
# 現在のAWSアカウントIDを取得
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"
```

2. **IAM Identity Providerの作成**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

3. **信頼ポリシーファイルの作成**
```bash
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:keylium/fastapi-x-ray-with-otel:*"
        }
      }
    }
  ]
}
EOF
```

4. **IAMロールの作成**
```bash
aws iam create-role \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --assume-role-policy-document file://trust-policy.json
```

5. **必要なポリシーのアタッチ**
```bash
# ECRアクセス権限
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# ECSアクセス権限
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# SSM Parameter Store アクセス権限（ADOT Collector設定用）
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
```

### 2. GitHubシークレットの設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下のシークレットを設定：

- `AWS_ROLE_TO_ASSUME`: 作成したIAMロールのARN
  ```
  arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-FastAPI-XRay-Role
  ```

## ワークフローの動作

### トリガー条件
- **mainブランチへのプッシュ**: 自動ビルド・デプロイ実行
- **プルリクエスト**: テストのみ実行

### ジョブ構成

#### 1. Test Job
- uvパッケージマネージャーのセットアップ
- Python 3.11のインストール
- 依存関係のインストール
- ローカルテストの実行

#### 2. Build and Deploy Job（mainブランチのみ）
- AWS認証（OIDC）
- ECRログイン
- ECRリポジトリの確認・作成
- Dockerイメージのビルド・プッシュ
- ECSサービスの更新（存在する場合）

### イメージタグ戦略
- `latest`: 最新のmainブランチビルド
- `{git-sha}`: 特定のコミットハッシュ

## 手動実行

### ローカルでのテスト
```bash
# ローカルテストの実行
./scripts/test-local.sh
```

### 手動デプロイ
```bash
# 手動でのAWSデプロイ
./scripts/deploy.sh
```

## トラブルシューティング

### よくある問題

1. **AWS認証エラー**
   - IAMロールのARNが正しく設定されているか確認
   - 信頼ポリシーのリポジトリ名が正しいか確認

2. **ECRプッシュエラー**
   - ECRリポジトリが存在するか確認
   - IAMロールにECR権限があるか確認

3. **ECS更新エラー**
   - ECSクラスター・サービスが存在するか確認
   - IAMロールにECS権限があるか確認

### ログの確認
GitHub ActionsのログはGitHubリポジトリの「Actions」タブで確認できます。

### 手動でのECRリポジトリ作成
```bash
aws ecr create-repository --repository-name fastapi-xray-otel-fastapi-app --region ap-northeast-1
```

## 必要なAWS権限の詳細

GitHub Actions CI/CDパイプラインが正常に動作するために、以下のAWS権限が必要です：

### ECR（Elastic Container Registry）権限
- `ecr:GetAuthorizationToken` - ECRログイン用
- `ecr:BatchCheckLayerAvailability` - イメージレイヤー確認用
- `ecr:GetDownloadUrlForLayer` - イメージダウンロード用
- `ecr:BatchGetImage` - イメージ取得用
- `ecr:DescribeRepositories` - リポジトリ情報取得用
- `ecr:CreateRepository` - リポジトリ作成用
- `ecr:InitiateLayerUpload` - イメージアップロード開始用
- `ecr:UploadLayerPart` - イメージレイヤーアップロード用
- `ecr:CompleteLayerUpload` - イメージアップロード完了用
- `ecr:PutImage` - イメージプッシュ用

### ECS（Elastic Container Service）権限
- `ecs:DescribeClusters` - クラスター状態確認用
- `ecs:DescribeServices` - サービス状態確認用
- `ecs:UpdateService` - サービス更新用（新しいイメージでのデプロイ）

### SSM Parameter Store権限
- `ssm:GetParameter` - ADOT Collector設定取得用
- `ssm:GetParameters` - 複数パラメータ取得用

### 推奨されるマネージドポリシー
- `AmazonEC2ContainerRegistryPowerUser` - ECR操作用
- `AmazonECS_FullAccess` - ECS操作用（本番環境では最小権限に調整推奨）
- `AmazonSSMReadOnlyAccess` - SSMパラメータ読み取り用

## セキュリティ考慮事項

- OIDC連携により、長期的なAWSアクセスキーの管理が不要
- IAMロールの権限は最小限に設定
- GitHubシークレットは暗号化されて保存
- ブランチ保護ルールの設定を推奨
- 本番環境では、ECS_FullAccessの代わりにより制限的なカスタムポリシーの使用を推奨

## CI/CDパイプラインの拡張

将来的に以下の機能を追加できます：
- 自動テストの拡充
- セキュリティスキャン
- パフォーマンステスト
- ステージング環境へのデプロイ
- Slack通知
- ロールバック機能
