import PreloadStore from 'preload-store';
import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  titleToken() {
    return I18n.t('login.logging_in');
  },

  model(params) {
    if (PreloadStore.get("token_login")) {
      return PreloadStore.getAndRemove("token_login").then(json => _.merge(params, json));
    }
  },

  afterModel(model) {
    console.log(model);
    // confirm token here so email clients who crawl URLs don't invalidate the link
    if (model) {
      return ajax({ url: `/session/token-login/${model.token}.json`, dataType: 'json', type: 'PUT' });
    }
  }
});
