data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${var.project_name}-ecsTaskExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ssm_parameter_policy" {
  version = "2012-10-17"
  
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
    ]
  }
}

resource "aws_iam_policy" "ssm_parameter_policy" {
  name        = "${var.project_name}-ssm-parameter-policy"
  description = "IAM policy for SSM Parameter Store access"
  policy      = data.aws_iam_policy_document.ssm_parameter_policy.json

  tags = {
    Name = "${var.project_name}-ssm-parameter-policy"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_ssm_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_parameter_policy.arn
}

data "aws_iam_policy_document" "ecs_task_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role.json

  tags = {
    Name = "${var.project_name}-ecsTaskRole"
  }
}

data "aws_iam_policy_document" "xray_policy" {
  version = "2012-10-17"
  
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "xray_policy" {
  name        = "${var.project_name}-xray-policy"
  description = "IAM policy for X-Ray and CloudWatch access"
  policy      = data.aws_iam_policy_document.xray_policy.json

  tags = {
    Name = "${var.project_name}-xray-policy"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_xray_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.xray_policy.arn
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name = "${var.project_name}-github-actions-oidc"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  version = "2012-10-17"
  
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:keylium/fastapi-x-ray-with-otel:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

data "aws_iam_policy_document" "github_actions_policy" {
  version = "2012-10-17"
  
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:CreateRepository",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
    ]
  }
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "${var.project_name}-github-actions-policy"
  description = "IAM policy for GitHub Actions CI/CD"
  policy      = data.aws_iam_policy_document.github_actions_policy.json

  tags = {
    Name = "${var.project_name}-github-actions-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
