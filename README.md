# auto-secaudit

## 概要

Docker Compose を使って下記のツールが連携できるようにしてみました

- [Jenkins](https://hub.docker.com/_/jenkins/)
- [OWASP ZAP](https://hub.docker.com/r/owasp/zap2docker-stable/)
- [Faraday](https://hub.docker.com/r/infobyte/faraday/)

## 目的

デプロイのタイミングで脆弱性診断を行えるようにします

想定している使い方は下記になります

1. Jenkins から シェルの実行を行う
2. OWASP ZAP のAPI 経由でサイトの脆弱性診断
3. 脆弱性診断の結果を Faraday で確認
4. 上記をひと通り試した後、デプロイに組み込む
5. 自動診断環境の完成

## 注意

許可を得たサイトのみ脆弱性診断を実施して下さい

## 環境

- Windows 7
- DockerToolbox 1.11.2
- Virtualbox 5.0.16
- Git 2.9.0.windows.1

## 使い方

Windows 7 の場合で記載していきます

### 準備

- [DockerToolbox](https://www.docker.com/products/docker-toolbox) のインストール
（同梱されてるVirtualboxもインストール）

- [Git](https://git-for-windows.github.io/) のインストール

- フォルダの作成
`C:\Users\{ユーザー名}\docker\`

### 起動

Docker QuickStart Terminal を起動し、コマンドを叩きます

```
$ cd /c/Users/{ユーザー名}/docker/
$ git clone https://github.com/toubaru/auto-secaudit.git
$ cd auto-secaudit
$ docker-machine create --driver virtualbox auto-secaudit
$ eval $(docker-machine env auto-secaudit)
$ docker-compose up -d
```

### 各サービスへのアクセス方法

| サービス       | URL                                                                         |
|:--------------|:-------------------------------------------------------------|
| Jenkins        | http://{HOST_IP}:8080/                                           |
| OWASP ZAP | http://{HOST_IP}:8090/                                           |
| Faraday       | http://{HOST_IP}/reports/_design/reports/index.html |

`./jenkins_shell/jenkins-zap-ascan.sh`

### Jenkins - ジョブの登録

新規ジョブを作成し、下記のスクリプトを登録
```
./jenkins_shell/jenkins-zap-ascan.sh
```

診断したい環境に合わせて、スクリプト内のスキャン設定を書き換えて下さい

```bash
#スキャン設定-----------------
#診断対象URL
scan_target="http://192.168.99.101/app/posts"
#自動ログイン設定
loginUrl="http://192.168.99.101/app/users/login"
loginRequest="_method=POST&data[User][username]={%username%}&data[User][password]={%password%}"
username="tobaru"
password="1234"
loggedInIndicatorRegex="\Qようこそ${username}さん\E"
#logoutInIndicatorRegex="\Q\E"
#ログイン認証方式
authMethodName="formBasedAuthentication"
#スキャン方式
contextname="acrive-scan"
#最大スレッド数
max_children="10"
#-----------------------------
```

変更箇所

| # | 変数 | 意味  |
| :-- |:-----------|:------------|
| 1 | scan_target   | 診断対象のURL |
| 2 | loginUrl         | ログイン処理のURL |
| 3 | loginRequest  | ログイン認証時のPOSTパラメータを記載します<br/>[%username%] -> #4 の変数の値が埋め込まれます<br/>[%password%]  -> #5 の変数の値が埋め込まれます|
| 4 | username      | ログインユーザのID |
| 5 | password      | ログインユーザのパスワード |
| 6 | loggedInIndicatorRegex | ログイン状態を示す文字列を記載<br/>これで、ZAPがログインしているかどうかを判断できます。<br/>例）"ようこそ○○さん" 等|
| 7 | logoutInIndicatorRegex | ログアウト状態を示す文字列を記載<br/>※#6 か #7 の変数どちらかを有効にする |

### Jenkins - ビルド実行

自動診断完了後、XMLレポートが生成されます

###  Faraday - 診断レポート閲覧

自動的にFaradayに取り込まれます

レポートの画面にアクセスすることで診断結果が閲覧できます

## 補足

- [OWASP ZAP GUI版](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) を使ってると理解が早いと思います