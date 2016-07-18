import { popupAjaxError } from 'discourse/lib/ajax-error';
import { urlValid } from 'discourse/lib/utilities';
import computed from 'ember-addons/ember-computed-decorators';
import InputValidation from 'discourse/models/input-validation';

export default Ember.Controller.extend({
  actions: {
    loadMore() {
      this.get('model').loadMore();
    }
  }
});
