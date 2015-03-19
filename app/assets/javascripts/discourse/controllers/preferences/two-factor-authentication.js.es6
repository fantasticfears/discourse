export default Ember.ObjectController.extend({
  enabledTwoFactorAuthentication: function() {
    console.log(this.get('user'));
    return this.get('user').get('enabled_two_factor_authentication')
  }.property('enabledTwoFactorAuthentication'),

  savingStatus: function() {
    if (this.get('saving')) {
      return I18n.t('saving');
    } else {
      return I18n.t('save');
    }
  }.property('saving'),

  actions: {
    save() {
      this.setProperties({ saved: false, saving: true });

      const self = this;
      Discourse.ajax(this.get('user.path') + '/preferences/two-factor-authentication', {
        type: 'PUT',
        data: {
          secret: self.get('data'),
          code: self.get('code')
        }
      }).then(function() {
        self.setProperties({
          saved: true,
          saving: false,
          enabledTwoFactorAuthentication: true
        });
      }).catch(function() {
        self.set('saving', false);
        bootbox.alert(I18n.t('generic_error'));
      });
    },

    revoke() {
      const self = this;
      Discourse.ajax(this.get('user.path') + '/preferences/revoke-two-factor-authentication', {
        type: 'PUT',
        data: { revoke: true }
      }).then(function() {
        self.setProperties({
          enabledTwoFactorAuthentication: false
        });
      }).catch(function() {
        bootbox.alert(I18n.t('generic_error'));
      });
    }

  }
});
