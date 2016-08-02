import { categoryBadgeHTML } from 'discourse/helpers/category-link';
import Category from 'discourse/models/category';
import { on } from 'ember-addons/ember-computed-decorators';
import StringBuffer from 'discourse/mixins/string-buffer';

export default Ember.Component.extend(StringBuffer, {
  @computed('placeholderKey')
  placeholder(placeholderKey) {
    return placeholderKey ? I18n.t(this.get('placeholderKey')) : null;
  },

  renderString(buffer) {
    const placeholder = this.get('placeholder');

    buffer.push("<input class='group-selector' ");
    if (placeholder) {
      buffer.push(`placeholder='${placeholder}' `);
    }
    buffer.push("type='text' name='groups'");
  },

  @on('didInsertElement')
  _initializeAutocomplete() {
    const self = this,
          template = this.container.lookup('template:category-selector-autocomplete.raw'),
          regexp = new RegExp(`href=['\"]${Discourse.getURL('/c/')}([^'\"]+)`);

    this.$('input').autocomplete({
      items: this.get('categories'),
      single: false,
      allowAny: false,
      dataSource(term) {
        return Category.list().filter(category => {
          const regex = new RegExp(term, 'i');
          return category.get('name').match(regex) &&
            !_.contains(self.get('blacklist') || [], category) &&
            !_.contains(self.get('categories'), category) ;
        });
      },
      onChangeItems(items) {
        const categories = _.map(items, link => {
          const slug = link.match(regexp)[1];
          return Category.findSingleBySlug(slug);
        });
        Em.run.next(() => self.set('categories', categories));
      },
      template,
      transformComplete(category) {
        return categoryBadgeHTML(category, {allowUncategorized: true});
      }
    });
  }
});
