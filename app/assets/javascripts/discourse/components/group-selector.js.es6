import { on, computed } from 'ember-addons/ember-computed-decorators';
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
          template = this.container.lookup('template:group-selector-autocomplete.raw');
    let selectedGroups;

    this.$('input').autocomplete({
      allowAny: false,
      template,
      onChangeItems(items) {
        selectedGroups = items;
        self.set('groupNames', items.join(','));
      },
      transformComplete: g => g.name,
      dataSource: term => {
        return self.get('groupFinder')(term).then(groups => {
          if (!selectedGroups) {
            return groups;
          }

          return groups.filter(group => {
            return !selectedGroups.any(s => s === group.name);
          });
        });
      }
    });
  }
});
