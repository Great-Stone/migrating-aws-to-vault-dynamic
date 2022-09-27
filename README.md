# Load IAM and Create Vault AWS Secret Engine

> Terraform CLI 1.3.0
> Vault Server 1.11.3
> Python 3.9.12

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

> boto3 문서 : <https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html>
> python에 필요한 `boto3`를 설치하고 `main.py`를 실행하여 `policies_data.json` 생성

```bash
pip install boto3
```

```bash
python ./script/main.py
```

## Run Terraform

> 실행위치에 AWS 자격증명이 선언되었으므로 (`~/.aws/credentials`) aws 프로바이더에 따로 설정은 필요하지 않음
> `vault_addr` 입력 변수에 사용하는 Vault 서버의 주소 설정 필요
> vault 프로바이더에 vault에 AWS Secret Engine 활성화 및 구성가능한 자격증명 구성해야 필요
> `vault_aws_secret_backend`에서는 Vault가 AWS에 iam_user를 생성가능한 `access_key`와 `secret_key`를 설정 필요

```bash
$ terraform apply
```