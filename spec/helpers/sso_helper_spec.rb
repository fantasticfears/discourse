require 'rails_helper'
require_dependency 'single_sign_on'

describe SsoHelper do
  describe 'verbose_sso_log' do
    before do
      @sso = SingleSignOn.new
      @sso.username = 'username'
      @sso.email = 'email@example.com'
    end

    it 'log when verbose_sso_logging enabled' do
      SiteSetting.verbose_sso_logging = true
      Rails.logger.expects(:warn).once.with do |s|
        s.include?("Verbose SSO log:") &&
            s.include?("username: username") &&
            s.include?("email: email@example.com")
      end

      verbose_sso_log("test", @sso.diagnostics)
    end

    it "doesn't log when disabled" do
      Rails.logger.expects(:warn).never
      verbose_sso_log("test", @sso.diagnostics)
    end
  end
end
