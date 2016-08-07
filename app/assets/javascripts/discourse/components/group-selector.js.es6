import { on, default as computed } from 'ember-addons/ember-computed-decorators';
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

    this.$('input').autocomplete({
      items: this.get('groups'),
      single: false,
      allowAny: false,
      dataSource(term) {
        return Group.list().filter(group => {
          const regex = new RegExp(term, 'i');
          return group.get('name').match(regex) &&
            !_.contains(self.get('blacklist') || [], group) &&
            !_.contains(self.get('groups'), group) ;
        });
      },
      onChangeItems(items) {
        const groups = Group.list().filter(group => {
          if (items.any(group.get('name'))) {
            return group;
          }
        });
        Em.run.next(() => self.set('groups', groups));
      },
      template,
      transformComplete: g => g.name
    });
  }
});
