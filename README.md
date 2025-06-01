# FastAPI X-Ray with OpenTelemetry

ECS上のFastAPIアプリケーションにX-Ray + OpenTelemetryによる自動計装トレースを導入（Terraform構築）

## 概要

このプロジェクトは、ECS上で稼働するFastAPIアプリケーションに対して、OpenTelemetryを使用した自動計装によるトレース機能を導入し、AWS X-Rayにトレース情報を送信する構成を提供します。

## アーキテクチャ

- **FastAPI**: Webアプリケーションフレームワーク
- **OpenTelemetry**: 自動計装によるトレース収集
- **AWS Distro for OpenTelemetry Collector (ADOT)**: サイドカーコンテナとしてトレースデータを収集・転送
- **AWS X-Ray**: トレースデータの可視化・分析
- **ECS Fargate**: コンテナ実行環境
- **Terraform**: インフラストラクチャ as Code

## ディレクトリ構造

```
├── app/                    # FastAPIアプリケーション
├── terraform/             # Terraformインフラ定義
├── docker/                # Dockerfiles
├── config/                # OpenTelemetry Collector設定
└── docs/                  # ドキュメント
```

## セットアップ

### 前提条件

- AWS CLI設定済み
- Docker
- Terraform
- Python 3.9+

### デプロイ手順

1. Terraformでインフラ構築
2. FastAPIアプリケーションのデプロイ
3. X-Rayコンソールでトレース確認

## 特徴

- **自動計装**: アプリケーションコードへの最小限の変更
- **サイドカーパターン**: ADOT Collectorをサイドカーとして配置
- **Infrastructure as Code**: Terraformによる再現可能なデプロイ
- **ベストプラクティス**: ECS/Fargateの推奨設定を適用
