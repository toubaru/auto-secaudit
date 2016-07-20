#!/bin/bash

#スキャン設定-----------------
#診断対象URL
scan_target="http://192.168.99.100:10080/weak-app/posts"
#自動ログイン設定
loginUrl="http://192.168.99.100:10080/weak-app/users/login"
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

#グローバル設定---------------
start_time=`date "+%Y%m%d-%H%M%S"`
zap_url="http://zap:8090"
report_path="/reports/"
#----------------------------

#Check Target URL
target_check=`curl -LI ${scan_target} -o /dev/null -w '%{http_code}\n' -s `

if [ "$target_check" -eq 200 -o "$target_check" -eq 301 -o "$target_check" -eq 302 > /dev/null 2>&1 ]; then
  echo "Target URL OK ... ${scan_target}"
 else
  echo "Target URL NG ... ${target_check}"
  echo "Target URL is Invalid - ex. zap-ascan.sh <http://Target-URL/>"
  exit 0
fi

if [ `curl "${zap_url}" > /dev/null 2>&1 ; echo $?` -ne 0 ]; then
  echo "Not found zap-api ... ${zap_url}"
  exit 0
fi

echo "------------ZAP API Booted--------------"

#セッション初期化
curl -s ""${zap_url}"/JSON/core/action/newSession/" > /dev/null 2>&1

#コンテキスト作成
contextId=`curl -s ""${zap_url}"/JSON/context/action/newContext/?contextName="${contextname}""| jq -r '.contextId'`

#スコープ設定
curl -s ""${zap_url}"/JSON/context/action/includeInContext/?contextName="${contextname}"&regex="${scan_target}".*" > /dev/null 2>&1

#ログイン方法設定
login_url_data=`echo "${loginUrl}"| nkf -WMQ | sed 's/=$//g' | tr -d '\n' | tr = %`
loginRequest_data=`echo "${loginRequest}"| nkf -WMQ | sed 's/=$//g' | tr -d '\n' | tr = %|sed "s/%/%25/g"`

curl -s ""${zap_url}"/JSON/authentication/action/setAuthenticationMethod/?contextId="${contextId}"&authMethodName="${authMethodName}"&authMethodConfigParams=loginUrl%3D"${login_url_data}"%26loginRequestData%3D"${loginRequest_data}"" > /dev/null 2>&1

#ログインインジケーター設定
loggedInIndicatorRegex_data=`echo "${loggedInIndicatorRegex}"| nkf -wMQ | tr = % | tr -d "\n"`
curl -s ""${zap_url}"/JSON/authentication/action/setLoggedInIndicator/?contextId="${contextId}"&loggedInIndicatorRegex="${loggedInIndicatorRegex_data}"" > /dev/null 2>&1

    #ログアウトインジケーター設定
    #logoutInIndicatorRegex_data=`echo "${logoutInIndicatorRegex}"| nkf -wMQ | tr = % | tr -d "\n"`
    #curl -s ""${zap_url}"/JSON/authentication/action/setLoggedOutIndicator/?contextId="${contextId}"&loggedOutIndicatorRegex="${logoutInIndicatorRegex_data}"" > /dev/null 2>&1

#ユーザ作成
userId=`curl -s ""${zap_url}"/JSON/users/action/newUser/?contextId="${contextId}"&name="${username}"" |jq -r '.userId'`

#ユーザ有効化
curl -s ""${zap_url}"/JSON/users/action/setUserEnabled/?contextId="${contextId}"&userId="${userId}"&enabled=true" > /dev/null 2>&1

#クレデンシャル設定
set_password=`curl -s ""${zap_url}"/JSON/users/action/setAuthenticationCredentials/?contextId="${contextId}"&userId="${userId}"&authCredentialsConfigParams=username%3D${username}%26password%3D${password}"`

#forcedUser
curl -s ""${zap_url}"/JSON/forcedUser/action/setForcedUser/?contextId="${contextId}"&userId="${userId}"" > /dev/null 2>&1

#-----------------------------

  user_name=`echo "${user_info}"|jq .credentials|jq -r '.username'`
  user_password=`echo "${user_info}"|jq .credentials|jq -r '.password'`
  echo "ZAPに設定されたユーザ:${username}でスキャンを実行します。"


#Spider実行
spider_id=`curl -s ""${zap_url}"/JSON/spider/action/scanAsUser/?url="${scan_target}"&contextId="${contextId}"&userId="${userId}"&maxChildren="${max_children}"&recurse=true"|jq -r '.scanAsUser'`

while [ `curl -s "${zap_url}"/JSON/spider/view/status/?scanId="${spider_id}"|jq -r '.status'` != "100" ]
do
	spider_progress=`curl -s "${zap_url}"/JSON/spider/view/status/?scanId="${spider_id}"|jq -r '.status'`
	echo "${scan_target}へのをSpiderを実行中..."${spider_progress}"%"
	sleep 1
done

#ActiveScan実行
scan_id=`curl -s ""${zap_url}"/JSON/ascan/action/scanAsUser/?url="${scan_target}"&contextId="${contextId}"&userId="${userId}"&maxChildren="${max_children}"&recurse=true"|jq -r '.scanAsUser'`

while [ `curl -s "${zap_url}"/JSON/ascan/view/status/?scanId="${scan_id}"|jq -r '.status'` != "100" ]
do
	ascan_progress=`curl -s "${zap_url}"/JSON/ascan/view/status/?scanId="${scan_id}"|jq -r '.status'`
	echo "${scan_target}へのActiveScanを実行中..."${ascan_progress}"%"
	sleep 1
done

 end_time=`date "+%Y%m%d-%H%M%S"`
 urls=`curl -s "${zap_url}"/JSON/core/view/urls/|jq -r '.urls'|grep "${scan_target}"|sed -e "s/\"//g" -e "s/\,$//g"`
 params=`curl -s "${zap_url}"/JSON/params/view/params/?site="${scan_target}"|jq -r '.Parameters[].Parameter[]|"\(.type)=\(.name)"'|sed -e 's/\s/\n/g' -e "s/^/  /g"|grep -v null | sort`

 json_data=`curl -s "${zap_url}"/JSON/core/view/alerts/?baseurl="${scan_target}"|jq .`
 echo ${json_data} > "${report_path}""${end_time}".json

 xml_date=`curl -s "${zap_url}"/OTHER/core/other/xmlreport/`
 echo ${xml_date} > "${report_path}""${end_time}".xml

 html_date=`curl -s "${zap_url}"/OTHER/core/other/htmlreport/`
 echo "${html_date}" > "${report_path}""${end_time}".html

 count_high=`echo ${json_data}|jq '.alerts[] | select(.risk == "High")|length'|wc -l`
 count_medium=`echo ${json_data}|jq '.alerts[] | select(.risk == "Medium")|length'|wc -l`
 count_low=`echo ${json_data}|jq '.alerts[] | select(.risk == "Low")|length'|wc -l`
 count_info=`echo ${json_data}|jq '.alerts[] | select(.risk == "Informational")|length'|wc -l`

 echo "------------------------------------"
 echo "Target : "${scan_target}""
 echo "Scan Summary : High/${count_high} Medium/${count_medium} Low/${count_low} Info/${count_info}"
 echo "------------------------------------"

 alerts=`curl -s "${zap_url}"/JSON/ascan/view/alertsIds/?scanId="${scan_id}"|jq -r '.alertsIds[]'`
 if [ -z "$alerts" ]; then
    echo "脆弱性は見付かりませんでした。"
    echo "\`\`\`"
 else

    while read LINE; do
     alert_id=(`echo "$LINE"`)
      alert_id_data=`curl -s "${zap_url}"/JSON/core/view/alert/?id="${alert_id}"| jq .alert`
      alert_id_risk=`echo ${alert_id_data} | jq -r '.risk'`
      alert_id_alert=`echo ${alert_id_data} | jq -r '.alert'`
      alert_id_url=`echo ${alert_id_data} | jq -r '.url'`
      alert_id_param=`echo ${alert_id_data} | jq -r '.param'`
      alert_id_attack=`echo ${alert_id_data} | jq -r '.attack'| nkf -Lu | perl -pe 's/\n/[CRLF]/g'| sed -e "s/\[CRLF\]$//g"`
      alert_id_evidence=`echo ${alert_id_data} | jq -r '.evidence'| nkf -Lu | perl -pe 's/\n/[CRLF]/g'| sed -e "s/\[CRLF\]$//g"`
      alert_id_id=`echo ${alert_id_data} | jq -r '.id'`
      alert_id_cweid=`echo ${alert_id_data} | jq -r '.cweid'`
      alert_id_wascid=`echo ${alert_id_data} | jq -r '.wascid'`

      echo "-----------------------"
      echo -e "リスクレベル:\\t"${alert_id_risk}""
      echo -e "アラート:\\t"${alert_id_alert}""
      echo -e "URL:\\t"${alert_id_url}""
      echo -e "パラメータ名:\\t"${alert_id_param}""
      echo -e "入力値:\\t"${alert_id_attack}""
      echo -e "エビデンス:\\t"${alert_id_evidence}""
      echo -e "Alert ID:\\t"${alert_id_id}""
      echo -e "CWE ID:\\t"${alert_id_cweid}""
      echo -e "WAS ID:\\t"${alert_id_wascid}""
      echo "-----------------------"

    done <<< "${alerts}"
    curl -s ""${zap_url}"/JSON/core/action/deleteAllAlerts/" > /dev/null 2>&1
 fi

exit 0
