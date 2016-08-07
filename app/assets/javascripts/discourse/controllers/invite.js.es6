import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { emailValid } from 'discourse/lib/utilities';
import computed from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend(ModalFunctionality, {
  needs: ['user-invited-show'],

  // If this isn't defined, it will proxy to the user model on the preferences
  // page which is wrong.
  emailOrUsername: null,
  hasCustomMessage: false,
  customMessage: null,
  inviteIcon: "envelope",

  @computed
  isAdmin() {
    return Discourse.User.currentProp("admin");
  },

  @computed('groups.[]')
  groupBlacklist(groups) {
    return Discourse.Site.currentProp('groups').filter(g => g.automatic === true);
  },

  @computed('isAdmin', 'emailOrUsername', 'invitingToTopic', 'isPrivateTopic', 'groups.[]', 'model.saving')
  disabled(isAdmin, emailOrUsernameVal, invitingToTopic, isPrivateTopic, groups, saving) {
    if (saving) return true;
    if (Ember.isEmpty(emailOrUsernameVal)) return true;
    const emailOrUsername = emailOrUsernameVal.trim();
    // when inviting to forum, email must be valid
    if (!invitingToTopic && !emailValid(emailOrUsername)) return true;
    // normal users (not admin) can't invite users to private topic via email
    if (!isAdmin && isPrivateTopic && emailValid(emailOrUsername)) return true;
    // when inviting to private topic via email, group name must be specified
    if (isPrivateTopic && Ember.isEmpty(groups) && emailValid(emailOrUsername)) return true;
    if (this.get('model.details.can_invite_to')) return false;
    return false;
  },

  @computed('isAdmin', 'emailOrUsername', 'model.saving', 'isPrivateTopic', 'groups.[]', 'hasCustomMessage')
  disabledCopyLink(isAdmin, emailOrUsernameVal, saving, isPrivateTopic, groups, hasCustomMessage) {
    if (hasCustomMessage) return true;
    if (saving) return true;
    if (Ember.isEmpty(emailOrUsernameVal)) return true;
    const emailOrUsername = emailOrUsernameVal.trim();
    // email must be valid
    if (!emailValid(emailOrUsername)) return true;
    // normal users (not admin) can't invite users to private topic via email
    if (!isAdmin && isPrivateTopic && emailValid(emailOrUsername)) return true;
    // when inviting to private topic via email, group name must be specified
    if (isPrivateTopic && Ember.isEmpty(groups) && emailValid(emailOrUsername)) return true;
    return false;
  },

  @computed('model.saving')
  buttonTitle(saving) {
    return saving ? 'topic.inviting' : 'topic.invite_reply.action';
  },

  // We are inviting to a topic if the model isn't the current user.
  // The current user would mean we are inviting to the forum in general.
  @computed('model')
  invitingToTopic(model) {
    return model !== this.currentUser;
  },

  @computed('isMessage')
  showCopyInviteButton(isMessage) {
    return (!Discourse.SiteSettings.enable_sso && !isMessage);
  },

  topicId: Ember.computed.alias('model.id'),

  // Is Private Topic? (i.e. visible only to specific group members)
  isPrivateTopic: Em.computed.and('invitingToTopic', 'model.category.read_restricted'),

  // Is Private Message?
  isMessage: Em.computed.equal('model.archetype', 'private_message'),

  // Allow Existing Members? (username autocomplete)
  @computed('invitingToTopic')
  allowExistingMembers: function(invitingToTopic) {
    return invitingToTopic;
  },

  // Show Groups? (add invited user to private group)
  @computed('isAdmin', 'emailOrUsername', 'isPrivateTopic', 'isMessage', 'invitingToTopic')
  showGroups(isAdmin, emailOrUsername, isPrivateTopic, isMessage, invitingToTopic) {
    return isAdmin && (emailValid(emailOrUsername) || isPrivateTopic || !invitingToTopic) && !Discourse.SiteSettings.enable_sso && Discourse.SiteSettings.enable_local_logins && !isMessage;
  },

  @computed('emailOrUsername')
  showCustomMessage(emailOrUsername) {
    return (this.get('model') === this.currentUser || emailValid(emailOrUsername));
  },

  // Instructional text for the modal.
  @computed('isMessage', 'invitingToTopic', 'emailOrUsername')
  inviteInstructions(isMessage, invitingToTopic, emailOrUsername) {
    if (Discourse.SiteSettings.enable_sso || !Discourse.SiteSettings.enable_local_logins) {
      // inviting existing user when SSO enabled
      return I18n.t('topic.invite_reply.sso_enabled');
    } else if (isMessage) {
      // inviting to a message
      return I18n.t('topic.invite_private.email_or_username');
    } else if (invitingToTopic) {
      // inviting to a private/public topic
      if (this.get('isPrivateTopic') && !this.get('isAdmin')) {
        // inviting to a private topic and is not admin
        return I18n.t('topic.invite_reply.to_username');
      } else {
        // when inviting to a topic, display instructions based on provided entity
        if (Ember.isEmpty(emailOrUsername)) {
          return I18n.t('topic.invite_reply.to_topic_blank');
        } else if (emailValid(emailOrUsername)) {
          this.set("inviteIcon", "envelope");
          return I18n.t('topic.invite_reply.to_topic_email');
        } else {
          this.set("inviteIcon", "hand-o-right");
          return I18n.t('topic.invite_reply.to_topic_username');
        }
      }
    } else {
      // inviting to forum
      return I18n.t('topic.invite_reply.to_forum');
    }
  },

  @computed('isPrivateTopic')
  showGroupsClass(isPrivateTopic) {
    return isPrivateTopic ? 'required' : 'optional';
  },

  @computed('model.inviteLink', 'isMessage', 'emailOrUsername')
  successMessage(inviteLink, isMessage, emailOrUsername) {
    if (inviteLink) {
      return I18n.t('user.invited.generated_link_message', {inviteLink: inviteLink, invitedEmail: emailOrUsername});
    } else if (this.get('hasGroups')) {
      return I18n.t('topic.invite_private.success_group');
    } else if (isMessage) {
      return I18n.t('topic.invite_private.success');
    } else if ( emailValid(emailOrUsername) ) {
      return I18n.t('topic.invite_reply.success_email', { emailOrUsername: emailOrUsername });
    } else {
      return I18n.t('topic.invite_reply.success_username');
    }
  },

  @computed('isMessage')
  errorMessage(isMessage) {
    return isMessage ? I18n.t('topic.invite_private.error') : I18n.t('topic.invite_reply.error');
  },

  @computed
  placeholderKey() {
    return (Discourse.SiteSettings.enable_sso || !Discourse.SiteSettings.enable_local_logins) ?
            'topic.invite_reply.username_placeholder' :
            'topic.invite_private.email_or_username_placeholder';
  },

  @computed
  customMessagePlaceholder() {
    return I18n.t('invite.custom_message_placeholder');
  },

  // Reset the modal to allow a new user to be invited.
  reset() {
    this.setProperties({
      groups: null,
      emailOrUsername: null,
      hasCustomMessage: false,
      customMessage: null
    }
    this.get('model').setProperties({
      groupNames: null,
      error: false,
      saving: false,
      finished: false,
      inviteLink: null
    });
  },

  actions: {

    createInvite() {
      const Invite = require('discourse/models/invite').default;
      const self = this;

      if (this.get('disabled')) { return; }

      const groupNames = this.get('model.groups').map(g => g.get('name')),
            userInvitedController = this.get('controllers.user-invited-show'),
            model = this.get('model');

      model.setProperties({ saving: true, error: false });

      const onerror = function(e) {
        if (e.jqXHR.responseJSON && e.jqXHR.responseJSON.errors) {
          self.set("errorMessage", e.jqXHR.responseJSON.errors[0]);
        } else {
          self.set("errorMessage", self.get('isMessage') ? I18n.t('topic.invite_private.error') : I18n.t('topic.invite_reply.error'));
        }
        model.setProperties({ saving: false, error: true });
      };

      if (this.get('hasGroups')) {
        return this.get('model').createGroupInvite(this.get('emailOrUsername').trim()).then(data => {
          model.setProperties({ saving: false, finished: true });
          this.get('model.details.allowed_groups').pushObject(Ember.Object.create(data.group));
          this.appEvents.trigger('post-stream:refresh');

        }).catch(onerror);

      } else {

        return this.get('model').createInvite(this.get('emailOrUsername').trim(), groupNames, this.get('customMessage')).then(result => {
              model.setProperties({ saving: false, finished: true });
              if (!this.get('invitingToTopic')) {
                Invite.findInvitedBy(this.currentUser, userInvitedController.get('filter')).then(invite_model => {
                  userInvitedController.set('model', invite_model);
                  userInvitedController.set('totalInvites', invite_model.invites.length);
                });
              } else if (this.get('isMessage') && result && result.user) {
                this.get('model.details.allowed_users').pushObject(Ember.Object.create(result.user));
                this.appEvents.trigger('post-stream:refresh');
              }
            }).catch(onerror);
      }
    },

    generateInvitelink() {
      const Invite = require('discourse/models/invite').default;
      const self = this;

      if (this.get('disabled')) { return; }

      const groupNames = this.get('groups').map(g => g.get('name')),
            userInvitedController = this.get('controllers.user-invited-show'),
            model = this.get('model');

      var topicId = null;
      if (this.get('invitingToTopic')) {
        topicId = this.get('model.id');
      }

      model.setProperties({ saving: true, error: false });

      return this.get('model').generateInviteLink(this.get('emailOrUsername').trim(), groupNames, topicId).then(result => {
              model.setProperties({ saving: false, finished: true, inviteLink: result });
              Invite.findInvitedBy(this.currentUser, userInvitedController.get('filter')).then(invite_model => {
                userInvitedController.set('model', invite_model);
                userInvitedController.set('totalInvites', invite_model.invites.length);
              });
            }).catch(function(e) {
              if (e.jqXHR.responseJSON && e.jqXHR.responseJSON.errors) {
                self.set("errorMessage", e.jqXHR.responseJSON.errors[0]);
              } else {
                self.set("errorMessage", self.get('isMessage') ? I18n.t('topic.invite_private.error') : I18n.t('topic.invite_reply.error'));
              }
              model.setProperties({ saving: false, error: true });
            });
    },

    showCustomMessageBox() {
      this.toggleProperty('hasCustomMessage');
      if (this.get('hasCustomMessage')) {
        if (this.get('model') === this.currentUser) {
          this.set('customMessage', I18n.t('invite.custom_message_template_forum'));
        } else {
          this.set('customMessage', I18n.t('invite.custom_message_template_topic'));
        }
      } else {
        this.set('customMessage', null);
      }
    }
  }

});
