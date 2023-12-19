# Redmine Git Hook

このプラグインは以下の二つの機能を提供します。

1. Git と Redmine のリポジトリを同期して Redmine 上で Git のコミットの履歴を参照可能にする
1. Git の Merge Request に追加されたコメントを自動で Redmine のチケットとして追加する

現在、２に関しては GitLab のみサポートしています。今後、GitHub のサポートも実施予定です。

## インストール

Redmine のプラグインのフォルダにて、以下を実行し、Redmine を再起動してください。  

```
$ cd /var/lib/redmine/plugins
$ git clone git@github.com:RedminePower/redmine_git_hook.git
$ bundle exec rake redmine:plugins:migrate NAME=redmine_git_hook RAILS_ENV=production
```
本プラグインの機能を有効にするには、Git と Redmine の両方で追加の設定が必要です。  
下記の手順を参考に設定を行ってください。

## Git と Redmine のレポジトリを同期する

### 機能

- プロジェクトの「リポジトリ」タブに設定した Git の履歴を表示する
- Git にプッシュされたら自動的に Redmine のリポジトリを更新する
- チケットの「関係しているリビジョン」にコミットへのリンクを追加する

### 設定方法

1. Git で同期したいプロジェクトに「Webhook」を設定する

   1. 以下のように同期させたい Redmine の URL を設定する。

      http://`[RedmineのURL]`/git_hook?project_id=`[Redmineのプロジェクトの識別子]`  
      例）`http://localhost/git_hook?project_id=plugin`

   1. `push` イベントのトリガーを有効にする。

1. Redmine のサーバに同期したいプロジェクトを git clone する

   1. サーバ内の任意のフォルダを選択する
   1. 同期したいプロジェクトを `git clone --mirror` する

      ```
      $ cd /home/apache/repos
      $ git clone --mirror [同期したい Git のプロジェクトを表す文字列]
      ```
      例）`git clone --mirror git@github.com:RedminePower/redmine_git_hook.git`

1. Redmine の同期させたいプロジェクトにて「リポジトリ」の設定を行う

   1. プロジェクトの設定画面から「リポジトリ」を選択し「新しいリポジトリ」をクリックする
   1. 以下の項目を設定する

      |項目|内容|
      |---|---|
      |識別子|リポジトリを判別するための任意の文字列|
      |リポジトリのパス|前の手順で `git clone` したリポジトリのパス <br> 例） `/home/apache/repos/redmine_git_hook.git` |

### 使用方法

1. Git に変更をプッシュする

   - 「リポジトリ」タブに表示されたコミット履歴が自動で更新される

1. コミットメッセージに `refs #[紐づけたいチケット番号]` をつけてコミットしてプッシュする  

   ※ 紐づけるためのキーワード（上では `refs` ）は以下で設定されているものを使用してください。  
    　[管理]-[設定]-[リポジトリ]-[参照用キーワード]

   - 指定したチケットの「関係しているリビジョン」に自動でコミットの履歴が追加される  

## Merge Request のコメントを Redmine のチケットとして追加する

### 機能

Merge Request と Redmine のレビューチケットをリンクさせ、Merge Request の操作をトリガーとして Redmine のチケットを更新する。

|Merge Request への操作|チケットの更新内容|
|---|---|
|コメント追加|新しい指摘チケットをレビューチケットの子チケットとして追加する|
|コメントへの返答|作成した指摘チケットにコメントを追加する|
|スレッド終了用のキーワードを <br> 含んだコメントを返答|作成した指摘チケットを終了する|
|Merge Request がマージ可能になる|本機能で追加された指摘チケットをすべて終了する|
|Merge Request がマージされる|本機能で追加された指摘チケットをすべて終了する|


これらの機能は、[Redmine Time Puncher](https://www.redmine-power.com/) と組み合わせることで、Git の Merge Request を利用したレビューをより快適にご利用いただけます。

- レビューの開催や指摘をチケットとして記録することで Redmine を使った管理が容易になる
- Merge Request にコメントしたタイミングが把握できることで工数入力をより正確かつ簡単に行える

### 設定方法

1. Git で同期したいプロジェクトに「Webhook」を設定する

   「レポジトリの同期」のための設定に加えて、`comment` イベントと `merge request` イベントを有効にする。

1. 同期したいプロジェクトの git clone と Redmine での「リポジトリ」の設定を行う

   「レポジトリの同期」のための設定と同様。設定済みなら追加の作業は不要。

1. Redmine で本プラグインをインストールすることで追加される「Git Webhookとの連携」の設定を行う

    1. 管理画面から「Git Webhookとの連携」を選択し、「新しいGit Webhookとの連携」をクリックする
    1. 以下の項目を設定する

      |項目|内容|
      |---|---|
      |タイトル|「Git Webhookとの連携」設定を判別するための任意の文字列|
      |有効|本設定を適用するかどうかのフラグ|
      |対象プロジェクト|本設定を適用するプロジェクトを正規表現で指定|
      |トラッカー|Merge Request のコメントから指摘チケットを作成するときのトラッカー|
      |終了時のステータス|指摘チケットの終了時のステータス|
      |終了用のキーワード|設定されたキーワードを含むコメントが追加されると対応する指摘チケットを終了する|

### 使用方法

1. Git の Merge Request と Redmine のレビューチケットの紐づけ

   以下のどちらかのやり方で Merge Request とレビューチケットを紐づける。

   - Merge Request の説明に `refs #[レビューチケットのチケット番号]` を追加する

     例）`refs #1234`

   - RedmineTimePuncher を利用してレビューチケットを作成し、Merge Request の URL を設定する

     1. RedmineTimePuncher の「レビュー」を選択する
     1. 「設定」ダイアログを開き「Gitとの連携」にチェックを入れる
     1. 「マージリクエストURL」に紐づけたい Merge Request の URL を設定しレビューチケットを作成する

1. Merge Request でコメントを追加する

   - 紐づけたレビューチケットの子チケットとして指摘チケットが作成される

1. Merge Request のコメントに返信する

   - 作成された指摘チケットにコメントが追加される

1. Merge Request のコメントに終了用のキーワードを含む返信をする

   - 作成された指摘チケットを終了する

1. Merge Request のすべてのスレッドが終了される、もしくはマージされる

   - 本プラグインによって作成された指摘チケットをすべて終了する
