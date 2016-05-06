require 'rails_helper'

describe SsoHelper do
  describe 'verbose_sso_log' do
    let(:sso) { SingleSignOn.new }

    it 'log when verbose_sso_logging enabled' do
      SiteSetting.verbose_sso_logging = true
      Rails.logger.expects(:warn).once

      sso.username = 'username'
      sso.email = 'email@example.com'
      expect(verbose_sso_log("test", sso.diagnostics)).to eq ("Verbose SSO log: test\n\nusername: username\nemail: email@example.com")
    end

    it "doesn't log when disabled" do
      Rails.logger.expects(:warn).never
      verbose_sso_log("test", sso.diagnostics)
    end
  end
end
