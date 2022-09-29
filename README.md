# Load IAM and Create Vault AWS Secret Engine

> 테스트한 환경 구성
> - Terraform CLI 1.3.0
> - Vault Server 1.11.3
> - Python 3.9.12

**[ 실행 순서 ]**
1. `boto3`를 사용하여 python에서 현재 AWS계정의 사용자에 할당된 정책 데이터를 json으로 저장
2. 저장된 json 파일을 terraform에서 읽어서 vault에 일괄 구성

## Setup AWS CLI

> python의 `boto3`에서 AWS 인증에 필요한 자격증명 구성

```bash
$ aws configure
AWS Access Key ID [****************3GML]: ************
AWS Secret Access Key [****************gxjD]: ****************
Default region name [ap-northeast-2]: ap-northeast-2
Default output format [None]:
```

## Setup & Run Python

```bash
pip install boto3
```

```bash
python ./script/main.py
```

- boto3 문서 : <https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html>
- python에 필요한 `boto3`를 설치하고 `main.py`를 실행하여 `policies_data.json` 생성
- `vault-`로 시작하는 iam_user는 제외

## Run Terraform

```bash
$ terraform apply
```

- 실행위치에 AWS 자격증명이 선언되었으므로 (`~/.aws/credentials`) aws 프로바이더에 따로 설정은 필요하지 않음
- `vault_addr` 입력 변수에 사용하는 Vault 서버의 주소 설정 필요
- Vault에 대한 인증정보는 로그인하여 환경변수로 구성
- `namespace` 필요시 프로바이더에 선언
- Vault 프로바이더에 vault에 AWS Secret Engine 활성화 및 구성가능한 자격증명은 `aws_iam_*`에서 생성
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "iam:AttachUserPolicy",
          "iam:CreateAccessKey",
          "iam:CreateUser",
          "iam:DeleteAccessKey",
          "iam:DeleteUser",
          "iam:DeleteUserPolicy",
          "iam:DetachUserPolicy",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedUserPolicies",
          "iam:ListGroupsForUser",
          "iam:ListUserPolicies",
          "iam:PutUserPolicy",
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup"
        ],
        "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/vault-*"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:GetGroup"
        ],
        "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/vault-*"]
      }
    ]
  }
  ```
- Vault Policy는 기존 `iam_user`에 따라 `READ` 권한 정책 자동 생성
- Vault AppRole은 기존 `iam_user`에 따라 `READ` 권한 정책 자동 생성
- 삭제 시 `revoke`동작 추가

