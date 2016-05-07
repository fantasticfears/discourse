require 'rails_helper'
require 'single_sign_on'

describe 'discourse sso session' do
  before do
    user = User.find_by(email: "sso_integration@email.com")
    user.destroy! if user

    @sso_url = "http://somesite.com/discourse_sso"
    @sso_secret = "shjkfdhsfkjh"

    @sso = SingleSignOn.new
    @sso.sso_url = @sso_url
    @sso.sso_secret = @sso_secret
    @sso.nonce = "testing"
    @sso.email = "sso_integration@email.com"
    @sso.username = "sam"
    @sso.name = "sam saffron"
    @sso.external_id = "100"
    @sso.avatar_url = "https://cdn.discourse.org/user_avatar.png"
    @sso.avatar_force_update = false
    @sso.admin = false
    @sso.moderator = false
    @sso.suppress_welcome_message = false
    @sso.require_activation = false
    @sso.custom_fields["a"] = "Aa"
    @sso.custom_fields["b.b"] = "B.b"

    SiteSetting.enable_sso = true
    SiteSetting.sso_url = @sso_url
    SiteSetting.sso_secret = @sso_secret
  end

  describe 'sso login process' do
    let(:return_url) { '/' }

    it 'rejects requests when it closes' do
      SiteSetting.enable_sso = false
      xhr :get, "/session/sso_login"
      expect(response).not_to be_success
    end

    it 'expires nonce immediately' do
      payload = @sso.payload
      dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
      dso.register_nonce(return_url)

      get "/session/sso_login?#{payload}"
      expect(response).to redirect_to(return_url)
      get "/session/sso_login?#{payload}"
      expect(response.status).to eq 419
    end

    context 'screens user' do
      let(:screen_ip_address) { '200.0.0.1' }
      before do
        ScreenedIpAddress.delete_all
        Fabricate(:screened_ip_address, ip_address: screen_ip_address, action_type: ScreenedIpAddress.actions[:block])
      end

      it 'screens ip and expires nonce' do
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        ActionDispatch::Request.any_instance.stubs(:remote_ip).returns(screen_ip_address)

        get "/session/sso_login?#{payload}"
        expect(response.status).to eq 403
        get "/session/sso_login?#{payload}"
        expect(response.status).to eq 419
      end
    end

    context 'with avatar' do
      before do
        FileHelper.stubs(:download).returns(Tempfile.new(["external-avatar", "png"]))
        FileHelper.stubs(:is_image?).returns(true)
        FastImage.stubs(:type).returns(:png)
        Upload.stubs(:is_actual_image?).returns(true)
      end

      it 'creates user and populates sso record when user is not created' do
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)

        expect {
          get "/session/sso_login?#{payload}"
        }.to change(User, :count).by(1)
         .and change(SingleSignOnRecord, :count).by(1)
         .and change(Upload, :count).by(1)

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record
        expect(user.active).to be_truthy
        expect(user.admin).to be_falsey
        expect(user.moderator).to be_falsey
        expect(user.email).to eq "sso_integration@email.com"
        expect(user.username).to eq "sam"
        expect(user.name).to eq "sam saffron"
        expect(user.uploaded_avatar_id).not_to be_nil
        expect(user.user_avatar.custom_upload_id).not_to be_nil
        expect(user.custom_fields["a"]).to eq "Aa"
        expect(user.custom_fields["b.b"]).to eq "B.b"
        expect(sso_record.external_id).to eq "100"
        expect(sso_record.external_username).to eq "sam"
        expect(sso_record.external_email).to eq "sso_integration@email.com"
        expect(sso_record.external_name).to eq "sam saffron"
        expect(sso_record.external_avatar_url).to eq "https://cdn.discourse.org/user_avatar.png"
      end
    end

    context 'when user is exists' do
      it 'updates last payload and external id if not matched' do
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record
        expect(sso_record.last_payload).to eq(@sso.unsigned_payload)

        @sso.nonce = "new_nonce"
        @sso.external_id = "updated"
        @sso.username = "random_new"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(user.username).to eq "sam"
        expect(sso_record.external_username).to eq "random_new"
        expect(sso_record.external_id).to eq "updated"
        expect(sso_record.last_payload).to eq(@sso.unsigned_payload)
      end

      it 'overrides attributes according to SiteSetting' do
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"


        @sso.nonce = "nonce1"
        @sso.name = "newname"
        @sso.username = "newusername"
        @sso.email = "newemail@gmail.com"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(user.username).not_to eq "newusername"
        expect(user.name).not_to eq "newname"
        expect(user.email).not_to eq "newemail@gmail.com"
        expect(sso_record.external_username).to eq "newusername"
        expect(sso_record.external_name).to eq "newname"
        expect(sso_record.external_email).to eq "newemail@gmail.com"


        SiteSetting.sso_overrides_email = true
        SiteSetting.sso_overrides_username = true
        SiteSetting.sso_overrides_name = true
        @sso.nonce = "nonce2"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"


        user = User.find_by(email: "newemail@gmail.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(user.username).to eq "newusername"
        expect(user.name).to eq "newname"
        expect(user.email).to eq "newemail@gmail.com"
        expect(sso_record.external_username).to eq "newusername"
        expect(sso_record.external_name).to eq "newname"
        expect(sso_record.external_email).to eq "newemail@gmail.com"
      end

      it 'overrides avatar according to SiteSetting' do
        UserAvatar.expects(:import_url_for_user).times(3)

        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}" # 1st invoke import_url_for_user


        @sso.nonce = "avatar_nonce1"
        @sso.avatar_url = "https://cdn.discourse.org/1.png"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(sso_record.external_avatar_url).to eq "https://cdn.discourse.org/1.png"


        # updates when url change if avatar_force_update is not set
        SiteSetting.sso_overrides_avatar = true
        @sso.nonce = "avatar_nonce2"
        @sso.avatar_url = "https://cdn.discourse.org/2.png"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"  # 2nd invoke import_url_for_user

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(sso_record.external_avatar_url).to eq "https://cdn.discourse.org/2.png"


        # url not changed
        @sso.nonce = "avatar_nonce3"
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(sso_record.external_avatar_url).to eq "https://cdn.discourse.org/2.png"


        # force update
        @sso.nonce = "avatar_nonce4"
        @sso.avatar_force_update = true
        payload = @sso.payload
        dso = DiscourseSingleSignOn.parse(payload, @sso_secret)
        dso.register_nonce(return_url)
        get "/session/sso_login?#{payload}"  # 3rd invoke import_url_for_user

        user = User.find_by(email: "sso_integration@email.com")
        sso_record = user.single_sign_on_record

        expect(response).to redirect_to(return_url)
        expect(sso_record.external_avatar_url).to eq "https://cdn.discourse.org/2.png"
      end
    end
  end
end

