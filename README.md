# 250-portal-backend

## 大まかなソース構造
* 設定系はconfigフォルダ内を参照
  * URLとControllerのメソッドの紐づけはconfig/routesフォルダ内を参照
  * credentials系（ソース検索しても出てこない設定値があれば大体これ）はconfig/credentialsフォルダ内を参照
* Controllerはapp/controllersフォルダ内を参照
  * ユーザー側(250-sales-front)や新会員基盤のAPIはsales（APIは別にすべきでした。申し訳ありません）
  * 管理側(250-portal-admin)はadmin
* DBのレコードをオブジェクト化したもの（ActiveRecordのModel）はapp/modelsフォルダ内を参照
* サービスクラスはapp/servicesまたはlibフォルダ内を参照
  * libのサブフォルダ内にはいろいろファイルがあったりするが、service.rbを経由して利用すること
  * 特に、MIXI Mの切り離しを行った決済系のサービスクラスはapp/services/payment_transactor.rbである
* メーラー系はapp/mailersフォルダ内を参照
  * メールのテンプレはapp/viewsフォルダ内を参照
* DBのマイグレーションはdb/migrateフォルダ内を参照

## Docker のバージョンを確認

Docker のバージョンは`3.0以上`に設定してください。

## セットアップ

```
$ docker-compose build
$ docker-compose run app rails db:create
$ docker-compose run app rails db:migrate
$ docker-compose up
```

## credential について

### test 環境用

key を関係者からもらい、それを `config/credentials/test.key` として保存してください。編集する場合は `bundle exec rails credentials:edit --environment test` を実行してください。

### 開発環境用

key を関係者からもらい、それを `config/master.key` として保存してください。編集する場合は `docker-compose run -e EDITOR=vim app rails credentials:edit` を実行してください。

## CI/CD について

### CI について

任意のブランチにコミットをプッシュすると CircleCI で `rubocop` と `rspec` が実行されます。
GitHub 上でも成功か失敗が表示されるので CI が失敗している場合は原則対応を行ってください。

テストに用いる Dockerfile や docker-compose 用の定義ファイルは専用のものを使用しています。
構成が変わった場合は必要に応じて以下のファイルも変更を行うようにしてください。

- docker/app/Dockerfile.test
- docker/docker-compose-test.yaml

なお、これらのファイルは CI 上でテストを行うためのもので、ローカル環境での利用は想定していません。
使用する場合はソースの変更がある度に app のビルドが必要となります。

### CD について

- `stg` というブランチにマージすると staging 環境(stg-api.pist6.com)にデプロイされます
  - topic ブランチ -> `develop` -> `staging` という順でマージしていきます
- `master` というブランチにマージすると production 環境(api.pist6.com)にデプロイされます
  - stagingでの動作確認が終わったものをproductionへリリースするという流れです。
  - topic ブランチ -> `develop` -> `staging` -> `master` という順でマージしていきます

#### DB migration

デプロイ時、DBへのmigrationも自動的に行われます。
大量にデータのあるテーブルへのmigrationなどは事前に計画を立てた上で、
デプロイ前にmigrationを行うなどの対応を行うようにしてください。

#### アプリ実行環境と環境変数の受け渡し

アプリはAWS ECS上でコンテナとして動いています。
実行に必要な環境変数の追加が発生する場合はAWSコンソール上から、
ECSのTask Definitionで追加の設定を行う必要があります。
秘匿情報の場合はAWS Systems ManagerのParameter StoreでSecureStringとして登録し、
Task DefinitionではParameter Storeから該当の値を読み込むようにしてください。

#### Task Definition一覧
staging・production環境それぞれにアプリ実行用とDB migration用の2つが存在しています。
環境変数の追加は全てに行ってください。

|実行環境   |名前                 |用途          |
|:---------|:---------------------|:-------------|
|staging   | pst-gt-stg           |アプリ実行用  |
|staging   | pst-gt-stg-migration |DB migration用|
|production|pst-gt-prd            |アプリ実行用  |
|production|pst-gt-prd-migration  |DB migration用|
