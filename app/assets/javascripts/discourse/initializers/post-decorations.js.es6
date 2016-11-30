import highlightSyntax from 'discourse/lib/highlight-syntax';
import lightbox from 'discourse/lib/lightbox';
import { withPluginApi } from 'discourse/lib/plugin-api';

export default {
  name: "post-decorations",
  initialize() {
    withPluginApi('0.1', api => {
      const siteSettings = api.container.lookup('site-settings:main');
      api.decorateCooked(highlightSyntax);
      api.decorateCooked(lightbox);
      // decorate topics with featured link yet without post body
      api.decorateCooked(($elem, m) => {
        if (!m || !$elem || !siteSettings.topic_featured_link_enabled || siteSettings.topic_featured_link_style === 'normal') { return; }

        const model = m.getModel(),
          categoryIds = Discourse.Site.current().get('topic_featured_link_allowed_category_ids');

        if (model.get('firstPost') && (categoryIds === undefined || !categoryIds.length || categoryIds.indexOf(model.get('topic.category.id')) !== -1)) {
          if (siteSettings.topic_featured_link_style === 'onebox' && $elem.children('p').children('a').length === 0) {
            $elem.show();
          } else {
            $elem.hide();
          }
        }
      }
      );
    });
  }
};
