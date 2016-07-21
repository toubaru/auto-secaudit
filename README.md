# auto-secaudit

## 概要

Docker Compose を使って下記のツールが連携できるようにしてみました

- [Jenkins](https://hub.docker.com/_/jenkins/)
- [OWASP ZAP](https://hub.docker.com/r/owasp/zap2docker-stable/)
- [Faraday](https://hub.docker.com/r/infobyte/faraday/)

## 目的

Jenkinsでデプロイ成功後に、自動で脆弱性診断を行える環境を作ります

## 注意

許可を得たサイトのみ脆弱性診断を実施して下さい

## 環境

- Windows 7
- DockerToolbox 1.11.2
- Virtualbox 5.0.16
- Git 2.9.0.windows.1

## 使い方

大まかな流れは下記になります

1. Git Hub から最新のソースを取得し、デプロイする
2. 1が成功した場合、自動診断のシェルの実行を行う
3. OWASP ZAP のAPI 経由でサイトの脆弱性診断
4. 脆弱性診断の結果を Faraday で確認

※Windows 7 の場合で記載していきます

### 準備

- [DockerToolbox](https://www.docker.com/products/docker-toolbox) のインストール
（同梱されてるVirtualboxもインストール）

- [Git](https://git-for-windows.github.io/) のインストール

- フォルダの作成 `C:\Users\{ユーザー名}\docker\`

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

| サービス       | URL                                                                         | 備考                            |
|:--------------|:-------------------------------------------------------------|:--------------------------|
| Jenkins        | http://{HOST_IP}:8080/                                           | アクセスする際、Administrator Password が<br/>求められたら下記コマンドで入手して下さい<br/>`$ docker logs jenkins` |
| OWASP ZAP | http://{HOST_IP}:8090/                                           |  |
| Faraday       | http://{HOST_IP}/reports/_design/reports/index.html |  |
| デモサイト    | http://{HOST_IP}:10080/weak-app/posts/                 | [ソース](https://github.com/toubaru/weak-app) |

### Jenkins - ジョブの登録（デモサイトにデプロイするジョブ）

新規ジョブ「weak-app」を作成し、ビルド時にシェルを実行するように登録

下記ファイルの中身をコピペします。
`./jenkins_shell/build-weak-app.sh`

※GitHubからソース落としてきてデモサイトに反映しているだけです

### Jenkins - ジョブの登録(ZAPのAPIを叩いて自動診断するジョブ)

新規ジョブ「weak-app-auto-secaudit」を作成し、ビルド時にシェルを実行するように登録

下記ファイルの中身をコピペします。
`./jenkins_shell/jenkins-zap-ascan.sh`

※診断したい環境に合わせて、スクリプト内のスキャン設定を書き換えて下さい

```bash
#スキャン設定-----------------
#診断対象URL
scan_target="http://192.168.99.100:10080/app/posts"
#自動ログイン設定
loginUrl="http://192.168.99.100:10080/app/users/login"
loginRequest="_method=POST&data[User][username]={%username%}&data[User][password]={%password%}"
username="toubaru"
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

| #   | 変数         | 意味  |
| :-- |:-----------|:------------|
| 1 | scan_target   | 診断対象のURL |
| 2 | loginUrl         | ログイン処理のURL |
| 3 | loginRequest  | ログイン認証時のPOSTパラメータを記載します<br/>[%username%] -> #4 の変数の値が埋め込まれます<br/>[%password%]  -> #5 の変数の値が埋め込まれます|
| 4 | username      | ログインユーザのID |
| 5 | password      | ログインユーザのパスワード |
| 6 | loggedInIndicatorRegex | ログイン状態を示す文字列を記載<br/>これで、ZAPがログインしているかどうかを判断できます。<br/>例）"ようこそ○○さん" 等|
| 7 | logoutInIndicatorRegex | ログアウト状態を示す文字列を記載<br/>※#6 か #7 の変数どちらかを有効にする |

### Jenkins - ジョブの更新（デモサイトにデプロイするジョブ）

「weak-app」にて、デプロイ成功後に「weak-app-auto-secaudit」のビルドを実行するように修正します

- ビルド後の処理の追加　→　他のプロジェクトのビルド
- 「weak-app-auto-secaudit」を指定
- 「安定している場合のみ起動」を指定
- 保存

### Jenkins - ビルド実行

「weak-app」をビルド実行

- Git Hub からソースを取得、デモサイトにソースが反映されます
- 正常終了後、「weak-app-auto-secaudit」のビルドが実行されます
- OWASP ZAP API 経由で自動診断が実行されます
- 自動診断完了後、XMLレポートが生成されます
`./volumes/reports/`

###  Faraday - 診断レポート閲覧

下記フォルダから自動的にFaradayに取り込まれます

`./volumes/reports/`

Faraday に取り込み完了後は下記フォルダに移動されます

`./volumes/reports/process/`

取り込み完了後、レポートの画面にアクセスすることで診断結果が閲覧できます

## 補足

- [OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project) を GUI で使うと、スクリプト内で何をやっているかが分かりやすいと思います
