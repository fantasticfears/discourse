require_dependency 'single_sign_on'

# Responsible for parse and generate SSO payload.
# Base class `SingleSignOn` can be a building block as of SSO provider.
class DiscourseSingleSignOn < SingleSignOn

  def self.sso_url
    SiteSetting.sso_url
  end

  def self.sso_secret
    SiteSetting.sso_secret
  end

  def self.generate_sso(return_path="/")
    sso = new
    sso.nonce = SecureRandom.hex
    sso.register_nonce(return_path)
    sso.return_sso_url = Discourse.base_url + "/session/sso_login"
    sso
  end

  def self.generate_url(return_path="/")
    generate_sso(return_path).to_url
  end

  def register_nonce(return_path)
    if nonce
      $redis.setex(nonce_key, NONCE_EXPIRY_TIME, return_path)
    end
  end

  def nonce_valid?
    nonce && $redis.get(nonce_key).present?
  end

  def return_path
    $redis.get(nonce_key) || "/"
  end

  def expire_nonce!
    if nonce
      $redis.del nonce_key
    end
  end

  def nonce_key
    "SSO_NONCE_#{nonce}"
  end

  def lookup_or_create_user(ip_address=nil)
    @ip_address = ip_address

    setup_models
    update_records
    post_actions

    @user_record.reload
  end

  private

  def find_by_email_or_initialize_user
    user = User.find_by_email(email)
    unless user
      try_name = name.presence
      try_username = username.presence

      user_params = {
        email: email,
        name: try_name || User.suggest_name(try_username || email),
        username: UserNameSuggester.suggest(try_username || try_name || email),
        ip_address: @ip_address
      }

      user = User.new(user_params)
    end

    user
  end

  def override_user_attributes
    if SiteSetting.sso_overrides_email && @user_record.email != email
      @user_record.email = email
    end

    if SiteSetting.sso_overrides_username && username.present? && @user_record.username != username
      @user_record.username = UserNameSuggester.suggest(username || name || email, @user_record.username)
    end

    if SiteSetting.sso_overrides_name && name.present? && @user_record.name != name
      @user_record.name = name || User.suggest_name(username.blank? ? email : username)
    end

    if SiteSetting.sso_overrides_avatar && avatar_url.present? && (
      avatar_force_update || @previous_avatar_url != avatar_url)
      UserAvatar.import_url_for_user(avatar_url, @user_record)
    end
  end

  def setup_models
    @user_record = SingleSignOnRecord.find_by(external_id: external_id).try(:user)
    unless @user_record
      @user_record = find_by_email_or_initialize_user
    end
    @sso_record = @user_record.single_sign_on_record || @user_record.build_single_sign_on_record

    # flags to enable post sso actions
    @is_new_user = @user_record.new_record?
    @previous_avatar_url = @sso_record.external_avatar_url
    @enqueue_welcome = false
  end

  def update_records
    @sso_record.last_payload = unsigned_payload
    @sso_record.external_id = external_id
    @sso_record.external_username = username
    @sso_record.external_email = email
    @sso_record.external_name = name
    @sso_record.external_avatar_url = avatar_url

    if !@user_record.active && !require_activation
      @user_record.active = true
      @enqueue_welcome = true
    end

    custom_fields.each do |k,v|
      @user_record.custom_fields[k] = v
    end

    @user_record.ip_address = @ip_address
    @user_record.admin = admin unless admin.nil?
    @user_record.moderator = moderator unless moderator.nil?

    @user_record.save!
    @sso_record.save!
  end

  def post_actions
    @user_record.reload

    unless admin.nil? && moderator.nil?
      Group.refresh_automatic_groups!(:admins, :moderators, :staff)
    end

    if @enqueue_welcome
      @user_record.enqueue_welcome_message('welcome_user') unless @suppress_welcome_message
    end

    if @is_new_user
      UserAvatar.import_url_for_user(avatar_url, @user_record) if avatar_url.present?
    else
      override_user_attributes
    end

    @user_record.save!
    @user_record.user_avatar.save!
  end
end
