import ModalFunctionality from 'discourse/mixins/modal-functionality';
import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend(ModalFunctionality, {
  needs: ['modal', 'application'],

  authenticate: null,
  loggingIn: false,
  loggedIn: false,

  showSpinner: function() {
    return this.get('loggingIn') || this.get('authenticate');
  }.property('loggingIn', 'authenticate'),

  loginDisabled: Em.computed.or('loggingIn', 'loggedIn'),
  loginRequired: Em.computed.alias('controllers.application.loginRequired'),

  actions: {
    verify() {
      var self = this;

      if (this.blank('twoFactorAuthenticationCode')) {
        self.flash(I18n.t('login.blank_username_or_password'), 'error');
        return;
      }

      this.set('loggingIn', true);

      Discourse.ajax("/session/verify_two_factor_authentication_code", {
        data: { code: this.get('twoFactorAuthenticationCode') },
        type: 'POST'
      }).then(function(result) {
        // Successful login
        console.log(result);
        if (result.error) {
          self.set('loggingIn', false);
          self.flash(result.error, 'error');
        } else {
          self.set('loggedIn', true);
          // Trigger the browser's password manager using the hidden static login form:
          var $hidden_login_form = $('#hidden-login-form');
          var destinationUrl = $.cookie('destination_url');
          if (self.get('loginRequired') && destinationUrl) {
            // redirect client to the original URL
            $.cookie('destination_url', null);
            $hidden_login_form.find('input[name=redirect]').val(destinationUrl);
          } else {
            $hidden_login_form.find('input[name=redirect]').val(window.location.href);
          }
          console.log($hidden_login_form.submit());
        }

      }, function() {
        // Failed to login
        self.flash(I18n.t('login.error'), 'error');
        self.set('loggingIn', false);
      });

      return false;
    }
  }

});
