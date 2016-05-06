module SsoHelper
  def verbose_sso_log(t, sso)
    if SiteSetting.verbose_sso_logging
      Rails.logger.warn("Verbose SSO log: #{t}\n\n#{sso}")
    end
  end
end
