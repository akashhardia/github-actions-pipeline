# frozen_string_literal: true

require 'bcrypt'

module Sales
  # ユーザーコントローラー
  # 補足：本ファイルで頻出しているcurrent_userはapp/controllers/concerns/portal_login.rbを参照（本クラスが継承しているApplicationControllerがincludeしているPortalLoginに存在する）
  class UsersController < ApplicationController
    skip_before_action :require_login!, only: [:show, :session_profile, :confirm, :create, :logout, :email_verify, :unsubscribe, :search_by_phone_number, :search_by_email, :search_by_id, :is_exist, :all_users, :login_flow_0, :login_flow_1, :create_from_new_system, :update_from_new_system, :token]
    before_action :ng_user_check, only: :create
    before_action :snakeize_params
    before_action :init_new_user_session, only: [:session_profile, :create]

    BASE_URL = "#{Rails.application.credentials.new_system[:base_url]}"
    REFERER = "#{Rails.application.credentials.new_system[:referer]}"

    # 新会員基盤からアカウントを作成した際に、新会員基盤のバックエンドから呼ばれる。
    # これは、既存のUsersテーブルやProfilesテーブルが250-portalに強く結びついているため。
    # /sales/api/users/create_from_new_system
    def create_from_new_system

      # MIXI Mの切り離しに伴い、MIXI Mからsixgram_idを生成されなくなるためダミーのsixgram_idを生成する
      uuid = SecureRandom.urlsafe_base64(12)
      created_user = nil

      # トランザクションを張る
      ActiveRecord::Base.transaction do

        # usersテーブルに作成
        created_user = User.create!(
          sixgram_id: uuid,
          email_verified: true,
          qr_user_id: params[:qr_user_id]
        )

        # profilesテーブルに作成
        profile = Profile.create!(
          user: created_user,
          family_name: params[:family_name],
          given_name: params[:given_name],
          family_name_kana: params[:family_name_kana],
          given_name_kana: params[:given_name_kana],
          birthday: params[:birthday],
          zip_code: params[:zip_code],
          prefecture: params[:prefecture],
          city: params[:city],
          address_line: params[:block],
          email: params[:email],
          mailmagazine: params[:mailmagazine_flg] == 1 ? true : false,
          phone_number: params[:phone_number],
          ng_user_check: params[:ng_user_check] == 1 ? true : false,
          address_detail: params[:building]
        )

        # 作成されたユーザーに対象となるクーポンを紐づける
        # 旧createから模倣
        Coupon.distribution(Time.zone.now).map do |available_coupon|
          UserCoupon.create!(coupon: available_coupon, user_id: created_user.id)
        end
      end

      render json: {
        old_user_id: created_user.id
      }
    end

    # アカウントを更新した際に新会員基盤から呼ばれる。
    # 250-portalの画面から更新した場合も、新会員基盤のAPIを叩き、そのAPIから呼ばれる。
    # /sales/api/users/update
    def update_from_new_system
      ActiveRecord::Base.transaction do

        # 更新対象のユーザーを更新
        # ※qr_user_idは基本的に更新はされないが、
        # ユーザー移行の際に元々qr_user_idを持っていなかったユーザーは新会員基盤側でqr_user_idを割り振られるので、
        # その際にはこちらにqr_user_idを同期してやる必要がある
        User.find_by(id: params[:old_user_id]).update!(
          email_verified: true,
          qr_user_id: params[:qr_user_id]
        )

        # 更新対象のユーザーのお客様情報を更新
        Profile.find_by(user_id: params[:old_user_id]).update!(
          family_name: params[:family_name],
          given_name: params[:given_name],
          family_name_kana: params[:family_name_kana],
          given_name_kana: params[:given_name_kana],
          birthday: params[:birthday],
          zip_code: params[:zip_code],
          prefecture: params[:prefecture],
          city: params[:city],
          address_line: params[:block],
          email: params[:email],
          mailmagazine: params[:mailmagazine_flg] == 1 ? true : false,
          phone_number: params[:phone_number],
          ng_user_check: params[:ng_user_check] == 1 ? true : false,
          address_detail: params[:building]
        )
      end

      head :ok
    end

    # セッションに紐づくお客様情報を取得-
    # ただし、ActiveRecordのProfileオブジェクトから取得した値を保持しているのであって、Profileオブジェクトそのものではないので注意
    # 本クラスの@session_profileはinit_new_user_sessionで初期化される
    # /sales/users/session_profile
    def session_profile
      att = @session_profile.attributes
      # お客様情報のキーはバックエンドではsnake_caseだが、フロントエンドではcamelCaseのため変換してやる
      profiles = att.transform_keys { |k| k.to_s.camelize(:lower) }

      render json: {
        # MIXI M廃止で本人確認がないため、とりあえずtrueを返しておく
        identityVerified: true,
        profiles: profiles.presence
      }
    end

    # /sales/users/confirm
    def confirm
      # 250-portalでのサインアップでしか用いられないため、形だけ残して廃止
      # （使われないはずだが、フロント側が混沌としていて確証が持てないため、メソッドだけ念のため残す）
      head :ok
    end

    # セッションに紐づくユーザー情報をシリアライズして返す
    # /sales/users
    def show
      serialized_current_user = current_user && ActiveModelSerializers::SerializableResource.new(current_user, serializer: Sales::CurrentUserSerializer, key_transform: :camel_lower)

      render json: { currentUser: serialized_current_user }
    end

    # セッションに紐づくユーザーのお客様情報をシリアライズして返す
    # /sales/users/profile
    def profile
      serialized_profile = current_user.profile.scoped_serializer(
        :family_name_kana, :given_name_kana,
        :birthday, :email, :zip_code, :prefecture, :city, :address_line,
        :full_name, :mailmagazine, :phone_number, :address_detail, :family_name, :given_name
      ).serializable_hash

      # MIXI Mを切り離したため常にfalse
      serialized_profile.store(:sixgramdata_change_flg, false)
      render json: CaseTransform.camel_lower(serialized_profile)
    end

    # セッションに紐づくユーザーのメアドをシリアライズして返す
    # /sales/users/email
    def email
      serialized_profile = current_user.profile.scoped_serializer(:email).serializable_hash
      render json: CaseTransform.camel_lower(serialized_profile)
    end

    # セッションに紐づくユーザーのメアド（認証が終わっていない）を返す
    # 認証メールの再送信のために必要
    # /sales/users/email_unchecked
    def email_unchecked
      lock_key = "profile_#{current_user.id}"
      new_email = Redis.current.get(lock_key)
      render json: { email: new_email }
    end

    # 旧会員基盤のフロントからお客様情報の更新
    # /sales/users
    def update
      # セッションに紐づくユーザーのお客様情報を取得（更新用オブジェクトを兼ねている）
      session_profile = SessionProfile.new(session[:user_auth_token])
      session_profile.attributes = includes_sixgramdata_update_profile_params.to_h

      api_result = nil
      api_result_body = []

      ActiveRecord::Base.transaction do

        if update_profile_params[:email] != current_user.profile.email
          # メアド変更が存在する場合

          # メール認証・新会員基盤連携用のワンタイムトークン生成
          uuid = SecureRandom.urlsafe_base64(12)

          # 新会員基盤に変更した情報を投げる（メール認証が済んでいないため、この段階では変更確定しない）
          api_result = session_profile.validate_personal_data(session[:this_system_user_id], uuid)

          if api_result.code == 200
            # response bodyに200が入るか否かで判別可能
            if api_result.body == 'true'
              # バリデーション成功のパターン

              # セッションに紐づくユーザーについて、メアド未検証状態・ワンタイムトークン・検証期限を設定する
              current_user.update!(email_verified: false, email_auth_code: uuid, email_auth_expired_at: Time.zone.now + 1.day)

              # ユーザーと未検証のメアドをRedisで持つ。これは主に検証メールの再送信を可能とするため
              lock_key = "profile_#{current_user.id}"
              Redis.current.set(lock_key, update_profile_params[:email])

              # 認証メールを送る
              # ※認証メールを踏むと、認証メールに含まれるワンタイムトークンが新会員基盤に投げられてユーザー更新が走る
              AuthorizeMailer.send_update_completed_to_user(current_user, uuid).deliver_later

              api_result_body = []
            else
              # バリデーションエラーのパターン
              api_result_body = JSON.parse(api_result.body)
            end
          else
            Rails.logger.info 'お客様情報更新でエラーが発生しました。詳細は新会員基盤のログをご参照ください'
            raise 'お客様情報更新でエラーが発生しました。詳細は新会員基盤のログをご参照ください'
          end
        else
          # リクエストを跨がないので結果だけ見ればよし
          api_result = session_profile.post_personal_data(session[:this_system_user_id])

          if api_result.code == 200
            if api_result_body == 'true'
              # バリデーション成功のパターン
              api_result_body = []
            else
              # バリデーションエラーのパターン
              api_result_body = JSON.parse(api_result.body)
            end
          else
            Rails.logger.info 'お客様情報更新でエラーが発生しました。詳細は新会員基盤のログをご参照ください'
            raise 'お客様情報更新でエラーが発生しました。詳細は新会員基盤のログをご参照ください'
          end
        end
      end

      serialized_current_user = ActiveModelSerializers::SerializableResource.new(current_user, serializer: Sales::CurrentUserSerializer, key_transform: :camel_lower)
      render json: { api_result: api_result_body, currentUser: current_user && serialized_current_user }
    end

    # メール認証の認証コードをメールで再送信する
    # /sales/users/send_auth_code
    def send_auth_code
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.users.email_already_verified') if current_user.email_verified
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.users.email_blank') if update_profile_params[:email].blank?

      ActiveRecord::Base.transaction do
        # 従来はワンタイムトークンを振り直していたが、新会員基盤との連携が壊れるのでuuidを振り直ししないようにする
        uuid = current_user.email_auth_code
        current_user.update!(email_verified: false, email_auth_expired_at: Time.zone.now + 1.day)

        AuthorizeMailer.resend_authorize_code_to_user(current_user, uuid).deliver_later
      end

      head :ok
    end

    # メール認証で送られてきたURLを踏んだ際に呼ばれる（お客様情報の更新確定処理）
    # /sales/users/email_verify/:uuid
    def email_verify
      # ワンタイムトークンから更新対象のユーザーを取得
      target_user = User.find_by!(email_auth_code: params[:uuid])
      return render json: target_user, serializer: Sales::CurrentUserSerializer, key_transform: :camel_lower if target_user.email_verified

      raise CustomError.new(http_status: :bad_request, code: :expired), I18n.t('custom_errors.users.email_auth_expired') if target_user.email_auth_expired_at < Time.zone.now

      # 新会員基盤で更新を確定
      # ※読んだ先のAPIから逆にこちらの更新処理（本controllerのupdate_from_new_system）が呼ばれる
      api_result = NewSystem::Service.post_update_profile_token(params[:uuid])

      # 失敗パターン
      if api_result.code != 200
        render json: { error: "お客様情報の更新に失敗しました" }
      end

      # 更新処理
      target_user.update!(email_verified: true)

      # 完了メールの送信
      AuthorizeMailer.send_authorize_completed_to_user(target_user).deliver_later

      # 認証メールの再送信はもう不要なため、Redisからメアドを削除
      lock_key = "profile_#{target_user.id}"
      Redis.current.del(lock_key)

      render json: target_user, serializer: Sales::CurrentUserSerializer, key_transform: :camel_lower
    end

    # ログアウト（セッション破棄）
    # ※新会員基盤からのログアウト処理はフロントで行われる
    # /sales/users/logout
    def logout
      reset_session

      head :ok
    end

    # ユーザー退会処理
    # /sales/users/:unsubscribe_uuid/unsubscribe
    def unsubscribe
      user = User.find_by(unsubscribe_uuid: params[:unsubscribe_uuid])
      # ターゲットユーザーが見つからない場合エラー
      raise CustomError.new(http_status: :bad_request, code: 'user_not_exist'), I18n.t('custom_errors.users.not_exist') if user.nil?
      # すでに退会済みの場合エラー
      raise CustomError.new(http_status: :bad_request, code: 'deleted_user'), I18n.t('custom_errors.users.already_unsubscribed') if user.deleted_at.present?

      require_login!

      # ターゲットユーザーがログインユーザーでない場合エラー
      raise CustomError.new(http_status: :unauthorized, code: 'different_uuid'), I18n.t('custom_errors.users.different_uuid') unless user == current_user

      user.update!(deleted_at: Time.zone.now)

      body1 = {
        user_id: current_user.id
      }

      api_result = JSON.parse(HTTParty.post(BASE_URL + '/api/user/delete', headers: { "Content-Type": "application/json", "Referer": REFERER }, body: body1.to_json()).body)
      if api_result.code == true
        AuthorizeMailer.send_unsubscribe_complete_mail_to_user(user).deliver_later
        reset_session
        head :ok
      else
        head :bad_request
      end
    end

    # マイページの会員QRコード表示に使用するAPI
    # /sales/users/qr_code
    def qr_code
      render json: current_user, serializer: UserQrCodeSerializer, key_transform: :camel_lower
    end

    # ユーザーの存在確認API
    # 新会員基盤から呼ばれる
    # 電話番号からユーザーの存在有無を返す
    # /sales/api/users/is_exist
    def is_exist
      is_exist_user = User.eager_load(:profile)
                          .order(created_at: :desc)
                          .exists?(profiles: { phone_number: params[:phone_number] })
      render json: is_exist_user
    end

    # ユーザーの検索API
    # 新会員基盤から呼ばれる
    # 電話番号からユーザー情報とそれに紐づくお客様情報を返す
    # /sales/api/users/search
    def search_by_phone_number
      user = User.eager_load(:profile).order(created_at: :desc).find_by(profiles: { phone_number: params[:phone_number] })
      render json: { user: user }, include: :profile
    end

    # ユーザーの検索API
    # 新会員基盤から呼ばれる
    # メアドからユーザー情報とそれに紐づくお客様情報を返す
    # /sales/api/users/search_by_email
    def search_by_email
      user = User.eager_load(:profile).where(profiles: { email: params[:email] }).where.not(profiles: { phone_number: nil }).order(created_at: :desc).first
      render json: { user: user }, include: :profile
    end

    # ユーザーの検索API
    # 新会員基盤から呼ばれる
    # こちら側のusersテーブルのidからユーザー情報とそれに紐づくお客様情報を返す
    # /sales/api/users/search_by_id
    def search_by_id
      user = User.find(params[:id])
      render json: { user: user }, include: :profile
    end

    # ユーザーの一覧取得API
    # 新会員基盤から呼ばれる
    # ページネーションが行われる
    # pageで何ページ目かを、per_pageで1ページに含む件数を指定できる
    # /sales/api/users/all_users
    def all_users
      users = User.eager_load(:profile).page(params[:page] || 1).per(params[:per_page] || 20) #.page(params[:page]).per(params[:perPage].to_i)
      usersTotal = User.count
      render json: { users: users, total: usersTotal }, include: :profile
    end


    # ログインフロー
    # ※code_verifierはバックが生成・送信し、code_challengeはバックが生成しフロントが送信する。
    # 【code_verifierをバックが生成・送信する理由】
    # 最終的に新会員基盤からuser_idを教わるのがバックエンドであるのでcode_verifierはバックが持ち送信する必要があるため。
    # 【code_challengeをフロントが送信する理由】
    # そして、code_challengeを新会員基盤に投げた後にトークンつきのリダイレクトが発生するので、リダイレクトを追従できるブラウザがcode_challengeを送信しなければならないため。


    # code_verifierを生成・保持し、フロントにcode_challengeを返す
    # /sales/users/login_flow_0
    def login_flow_0
      # code_verifierを生成し、セッションに持つ。
      code_verifier = LoginRequiredUuid.generate_uuid
      Rails.logger.info "DEBUG code_verifier is #{code_verifier}"

      # session[:code_verifier]が存在した場合にエラーを返却
      # return head :conflict unless session[:code_verifier].blank?
      
      session[:code_verifier] ||= code_verifier
      Rails.logger.info "DEBUG session[:code_verifier] is #{session[:code_verifier]}"

      # code_verifierをハッシュ化しcode_challengeとして返却する
      code_challenge = BCrypt::Password.create(session[:code_verifier])
      Rails.logger.info "DEBUG code_challenge is #{code_challenge}"

      session[:code_challenge] ||= code_challenge
      Rails.logger.info "DEBUG session[:code_challenge] is #{session[:code_challenge]}"

      Rails.logger.info "DEBUG login_flow_0 finish"

      render json: { code_challenge: session[:code_challenge] }
    end

    # フロントでは、code_challengeの送信・ログイン後に（成功していれば）tokenが発行される。
    # この際、新会員基盤からはフロントの/mypageへのリダイレクトとしてtokenが送信される。
    # そのためフロントからこのエンドポイントにtokenをPOST送信し、このエンドポイントは新会員基盤にtokenとcode_verifierをPOST送信する。
    # 上記のレスポンスとして、ログイン者の（新会員基盤における）user_idを受け取ることができるので、それをセッションに保持する。
    # /sales/users/login_flow_1
    def login_flow_1

      body1 = {
        token: params[:token],
        code_verifier: session[:code_verifier]
      }

      # 新会員基盤にtokenとcode_verifierを送り、ユーザーidを取得
      api_result1 = JSON.parse(HTTParty.post(BASE_URL + '/api/user_id', headers: { "Content-Type": "application/json", "Referer": REFERER }, body: body1.to_json()).body)
      new_system_user_id = api_result1['user_id']

      body2 = {
        user_id: new_system_user_id
      }
      # 上記で得たユーザーidによってユーザー情報を取得
      # ※時間があるときに、上記と同時に行えないか検討すること
      api_result2 = JSON.parse(HTTParty.post(BASE_URL + '/api/user', headers: { "Content-Type": "application/json", "Referer": REFERER }, body: body2.to_json()).body)

      if api_result2 == 'NG'
        Rails.logger.info "DEBUG login_flow_1 /api/user failed. token is #{ params[:token] } . code_verifier is #{ session[:code_verifier] } . new_system_user_id is #{new_system_user_id}"
        # セッション再生成
        reset_session

        return head :bad_request
      end

      # セッション再生成
      reset_session

      # 旧会員基盤のDB
      session[:this_system_user_id] = api_result2['old_user_id']
      # token
      session[:token] = params[:token]
      Rails.logger.info "DEBUG session[:token] is #{session[:token]}"

      # 元々はMIXI Mから返ってくるトークン。
      # セッションはRedisに入っているため、何かキーが必要になるので、とりあえず一意性が担保されているものとしてold_user_idを入れる。
      session[:user_auth_token] = api_result2['old_user_id']

      delete_secure_session

      head :ok
    end

    def token
      render json: { token: session[:token] }
    end

    # rails側でのsession情報がlaravelでも生きているかの関数
    def is_active

      body = {
        token: session[:token]
      }

      # 新会員基盤にtokenを送り、ユーザーがログイン状態か確認
      api_result = JSON.parse(HTTParty.post(BASE_URL + '/api/user_is_active', headers: { "Content-Type": "application/json", "Referer": REFERER }, body: body.to_json()).body)

      Rails.logger.info "DEBUG is_active api_result is #{api_result}"

      if api_result == 'not_exist'
        head :bad_request
      end
      
      head :ok
    end

    # ここ以降は上記のメソッドが使うメソッドであり、APIではない
    private

    # セッションに紐づくお客様情報を取得して保持する
    # 必要に応じて勝手に呼ばれる（before_actionなどを参照）
    # これが呼ばれた以降はレスポンスするまでsession_profileメソッドでお客様情報を参照可能
    def init_new_user_session
      @session_profile = SessionProfile.new(session[:user_auth_token])
    end

    # どこからも呼ばれていないはず（削除を失念したがリリース前なので一旦保留）
    def profile_params
      params.require(:profiles).permit(
        :family_name, :given_name, :family_name_kana,
        :given_name_kana, :birthday, :email, :email_confirmation, :zip_code,
        :prefecture, :city, :address_line, :mailmagazine, :address_detail,
        :agreement
      )
    end

    # ユーザー入力で通すものを設定
    def update_profile_params
      params.require(:profiles).permit(
        :email, :zip_code, :prefecture, :city, :address_line, :mailmagazine, :address_detail
      )
    end

    # ユーザー入力で通すものを設定
    def includes_sixgramdata_update_profile_params
      params.require(:profiles).permit(
        :family_name, :given_name, :family_name_kana, :given_name_kana, :birthday,
        :email, :zip_code, :prefecture, :city, :address_line, :mailmagazine, :address_detail, :email_confirmation
      )
    end

    # どこからも呼ばれていないはず（削除を失念したがリリース前なので一旦保留）
    def add_login_session(response)
      session[:user_auth_token] = response['legacy_auth_token']
      session[:access_token] = response['access_token']
      session[:refresh_token] = response['refresh_token']
    end

  end
end
