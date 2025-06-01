# GitHub Actions用IAM権限設定ガイド

## 概要

このドキュメントでは、GitHub Actions CI/CDパイプラインがAWSリソースにアクセスするために必要なIAM権限の詳細設定方法を説明します。

## 前提条件

- AWS CLIがインストール・設定済み
- 適切なAWS管理者権限を持つアカウント
- GitHubリポジトリ: `keylium/fastapi-x-ray-with-otel`

## ステップ1: OIDC Identity Providerの作成

```bash
# GitHub Actions用のOIDC Identity Providerを作成
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## ステップ2: 信頼ポリシーの作成

まず、現在のAWSアカウントIDを取得します：

```bash
# 現在のAWSアカウントIDを取得
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"
```

`trust-policy.json`ファイルを作成：

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

または、手動でファイルを作成する場合：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
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
```

**重要**: 手動作成の場合は`YOUR_ACCOUNT_ID`を実際のAWSアカウントIDに置き換えてください。

## ステップ3: IAMロールの作成

```bash
aws iam create-role \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --assume-role-policy-document file://trust-policy.json \
  --description "GitHub Actions role for FastAPI X-Ray with OpenTelemetry CI/CD"
```

## ステップ4: カスタムポリシーの作成（推奨）

最小権限の原則に従い、必要な権限のみを含むカスタムポリシーを作成します。

### ECR権限ポリシー

`ecr-policy.json`ファイルを作成：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:*:repository/fastapi-xray-otel-*"
    }
  ]
}
```

### ECS権限ポリシー

`ecs-policy.json`ファイルを作成：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ],
      "Resource": [
        "arn:aws:ecs:ap-northeast-1:*:cluster/fastapi-xray-otel",
        "arn:aws:ecs:ap-northeast-1:*:service/fastapi-xray-otel/fastapi-xray-otel"
      ]
    }
  ]
}
```

### SSM Parameter Store権限ポリシー

`ssm-policy.json`ファイルを作成：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-1:*:parameter/fastapi-xray-otel/*"
    }
  ]
}
```

### ポリシーの作成とアタッチ

```bash
# アカウントIDを取得（既に取得済みの場合はスキップ）
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECRポリシーファイルの作成
cat > ecr-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:$ACCOUNT_ID:repository/fastapi-xray-otel-*"
    }
  ]
}
EOF

# ECSポリシーファイルの作成
cat > ecs-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ],
      "Resource": [
        "arn:aws:ecs:ap-northeast-1:$ACCOUNT_ID:cluster/fastapi-xray-otel",
        "arn:aws:ecs:ap-northeast-1:$ACCOUNT_ID:service/fastapi-xray-otel/fastapi-xray-otel"
      ]
    }
  ]
}
EOF

# SSMポリシーファイルの作成
cat > ssm-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-1:$ACCOUNT_ID:parameter/fastapi-xray-otel/*"
    }
  ]
}
EOF

# ECRポリシーの作成
aws iam create-policy \
  --policy-name GitHubActions-FastAPI-XRay-ECR-Policy \
  --policy-document file://ecr-policy.json

# ECSポリシーの作成
aws iam create-policy \
  --policy-name GitHubActions-FastAPI-XRay-ECS-Policy \
  --policy-document file://ecs-policy.json

# SSMポリシーの作成
aws iam create-policy \
  --policy-name GitHubActions-FastAPI-XRay-SSM-Policy \
  --policy-document file://ssm-policy.json

# ポリシーのアタッチ
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-FastAPI-XRay-ECR-Policy

aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-FastAPI-XRay-ECS-Policy

aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-FastAPI-XRay-SSM-Policy
```

## ステップ5: 簡易設定（マネージドポリシー使用）

カスタムポリシーの代わりに、AWSマネージドポリシーを使用する場合：

```bash
# ECRアクセス権限
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# ECSアクセス権限
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# SSM Parameter Store アクセス権限
aws iam attach-role-policy \
  --role-name GitHubActions-FastAPI-XRay-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
```

## ステップ6: GitHubシークレットの設定

1. GitHubリポジトリ `keylium/fastapi-x-ray-with-otel` にアクセス
2. Settings > Secrets and variables > Actions に移動
3. 以下のシークレットを追加：

- **Name**: `AWS_ROLE_TO_ASSUME`
- **Value**: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-FastAPI-XRay-Role`

**重要**: `YOUR_ACCOUNT_ID`を実際のAWSアカウントIDに置き換えてください。

## ステップ7: 設定の確認

### IAMロールの確認

```bash
# ロールの詳細確認
aws iam get-role --role-name GitHubActions-FastAPI-XRay-Role

# アタッチされたポリシーの確認
aws iam list-attached-role-policies --role-name GitHubActions-FastAPI-XRay-Role
```

### アカウントIDの取得

```bash
# 現在のAWSアカウントIDを取得
aws sts get-caller-identity --query Account --output text
```

## トラブルシューティング

### よくあるエラー

1. **`AssumeRoleWithWebIdentity` エラー**
   - 信頼ポリシーのリポジトリ名が正しいか確認
   - OIDC Identity Providerが正しく作成されているか確認

2. **ECR権限エラー**
   - ECRポリシーのリソースARNが正しいか確認
   - リージョン（ap-northeast-1）が正しいか確認

3. **ECS権限エラー**
   - ECSクラスター・サービス名が正しいか確認
   - リソースARNの形式が正しいか確認

### デバッグコマンド

```bash
# アカウントIDを取得
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# IAMロールの信頼関係確認
aws iam get-role --role-name GitHubActions-FastAPI-XRay-Role --query 'Role.AssumeRolePolicyDocument'

# ポリシーの詳細確認
aws iam get-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-FastAPI-XRay-ECR-Policy
aws iam get-policy-version --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-FastAPI-XRay-ECR-Policy --version-id v1
```

## セキュリティのベストプラクティス

1. **最小権限の原則**: 必要最小限の権限のみを付与
2. **リソース制限**: 特定のリソースのみにアクセスを制限
3. **定期的な権限レビュー**: 不要な権限の削除
4. **ログ監視**: CloudTrailでAPI呼び出しを監視
5. **ブランチ保護**: mainブランチへの直接プッシュを制限

## 参考リンク

- [GitHub Actions OIDC設定ガイド](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Identity Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [ECR IAM権限](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security_iam_service-with-iam.html)
- [ECS IAM権限](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html)
