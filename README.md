# auto-secaudit

## 概要
Docker Compose を使って下記の環境を作れるようにしてみました
- [Jenkins](https://hub.docker.com/_/jenkins/)
- [OWASP ZAP](https://hub.docker.com/r/owasp/zap2docker-stable/)
- [Faraday](https://hub.docker.com/r/infobyte/faraday/)

目的は２つです
- Jenkins から OWASP ZAP のAPI 経由で自動診断
- 脆弱性診断の結果を Faraday で確認

## 環境
windows7  +  Docker Toolbox で試しました

## 使い方
### 起動
docker-compose up -d

### 各サービスへのアクセス方法
| サービス | URL  |
|:-----------|:------------|
| Jenkins     | http://{HOST_IP}:8080/     |
| OWASP ZAP     | http://{HOST_IP}/reports/_design/reports/index.html     |
| Faraday     | http://{HOST_IP}:8090/     |

### [Jenkins] 新規ジョブを作成し、下記のシェルを登録
./jenkins_shell/jenkins-zap-ascan.sh

### [Jenkins] スクリプト内のスキャン設定を診断対象に変更
診断したい環境に合わせて、スクリプト内のスキャン設定を書き換えて下さい
```
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

### [Jenkins] ビルド実行
診断完了後、XMLレポートが生成されます

###  [Faraday] 診断レポート閲覧
自動的にFaradayに取り込まれます

レポートの画面にアクセスすることで診断結果が閲覧できます