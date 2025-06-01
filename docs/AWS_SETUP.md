# AWS認証設定ガイド

## AWS Profile設定

このプロジェクトは`my-dev-profile`というAWSプロファイルを使用します。

### 1. AWS CLIプロファイルの作成

```bash
# プロファイル設定（対話式）
aws configure --profile my-dev-profile

# または手動でファイル編集
mkdir -p ~/.aws
```

### 2. 認証情報ファイルの設定

`~/.aws/credentials`ファイルを作成または編集：

```ini
[my-dev-profile]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

### 3. 設定ファイルの設定

`~/.aws/config`ファイルを作成または編集：

```ini
[profile my-dev-profile]
region = ap-northeast-1
output = json
```

### 4. 認証確認

```bash
# プロファイル設定確認
export AWS_PROFILE=my-dev-profile
aws configure list

# 認証テスト
aws sts get-caller-identity

# 正常な場合の出力例：
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/DevUser"
# }
```

## 必要なIAM権限

ECSとX-Rayを使用するため、以下の権限が必要です：

### 最小権限ポリシー例

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:*",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeAvailabilityZones",
                "elasticloadbalancing:*",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "ecr:*",
                "xray:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 管理者権限（開発環境推奨）

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
```

## トラブルシューティング

### プロファイルが見つからない場合

```bash
# 現在のプロファイル一覧確認
aws configure list-profiles

# プロファイル設定確認
cat ~/.aws/credentials
cat ~/.aws/config
```

### 権限エラーの場合

```bash
# 現在のユーザー情報確認
aws sts get-caller-identity --profile my-dev-profile

# 権限テスト
aws ecs list-clusters --profile my-dev-profile
aws xray get-service-graph --profile my-dev-profile
```

### 環境変数での設定

プロファイルファイルの代わりに環境変数でも設定可能：

```bash
export AWS_PROFILE=my-dev-profile
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=ap-northeast-1
```

## 次のステップ

AWS認証が正常に設定できたら：

1. ローカルテスト: `./scripts/test-local.sh`
2. AWSデプロイ: `./scripts/deploy.sh`
3. X-Rayコンソール確認: https://ap-northeast-1.console.aws.amazon.com/xray/home
