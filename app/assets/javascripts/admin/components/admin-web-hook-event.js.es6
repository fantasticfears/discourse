import computed from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  tagName: 'li',
  expandDetails: null,

  @computed('model.status')
  statusColorClasses(status) {
    if (!status) { return ''; }

    if (status >= 200 && status <= 299) {
      return 'text-successful';
    } else {
      return 'text-danger';
    }
  },

  @computed('model.created_at')
  createdAt(createdAt) {
    return moment(createdAt).format('YYYY-MM-DD HH:mm:ss');
  },

  @computed('model.duration')
  completion(duration) {
    const seconds = Math.floor(duration / 10.0) / 100.0;
    return I18n.t('admin.web_hooks.events.completion', { seconds });
  },

  actions: {
    redeliver() {
      return bootbox.confirm(I18n.t('admin.web_hooks.events.redeliver_confirm'), I18n.t('no_value'), I18n.t('yes_value'), result => {
        if (result) {
          ajax(`/admin/web_hooks/${this.get('model.web_hook_id')}/events/${this.get('model.id')}/redeliver`, { type: 'POST' }).then(json => {
            this.set('model', json.web_hook_event);
          }).catch(popupAjaxError);
        }
      });
    },

    toggleRequest() {
      if (this.get('expandDetails') !== 'request') {
        // TODO: Format helpers
        let headerJSON = JSON.parse(this.get('model.headers'));
        let keys = Object.keys(headerJSON);
        let headers = '';
        for (let i = 0; i < keys.length; ++i)
          headers += `${keys[i]}: ${headerJSON[keys[i]]}\n`;
        this.setProperties({
          headers,
          body: JSON.stringify(JSON.parse(this.get('model.payload'))),
          expandDetails: 'request'
        });
      } else {
        this.set('expandDetails', null);
      }
    },

    toggleResponse() {
      if (this.get('expandDetails') !== 'response') {
        this.setProperties({
          headers: this.get('model.response_headers'),
          body: this.get('model.response_body'),
          expandDetails: 'response'
        });
      } else {
        this.set('expandDetails', null);
      }
    }
  }

});
