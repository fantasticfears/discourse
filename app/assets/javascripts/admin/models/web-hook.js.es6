import RestModel from 'discourse/models/rest';
import Category from 'discourse/models/category';
import Group from 'discourse/models/group';
import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

export default RestModel.extend({
  content_type: 1, // json
  last_delivery_status: 1, // inactive
  wildcard_web_hook: false,
  verify_certificate: true,
  active: false,
  web_hook_event_types: null,
  filteredCategories: null,
  filteredGroups: null,

  @computed('wildcard_web_hook')
  webHookType: {
    get(wildcard) {
      return wildcard ? 'wildcard' : 'individual';
    },
    set(value) {
      this.set('wildcard_web_hook', value === 'wildcard');
    }
  },

  @observes('category_ids')
  updateFilteredCategories() {
    this.set('filteredCategories', Category.findByIds(this.get('category_ids')));
  },

  @observes('group_ids')
  updateFilteredGroups() {
    this.set('filteredGroups', Group.findByIds(this.get('group_ids')));
  },

  @computed('wildcard_web_hook', 'web_hook_event_types.[]')
  description(isWildcardWebHook, types) {
    let desc = '';

    types.forEach(type => {
      const name = `${type.name.toLowerCase()}_event`;
      desc += (desc !== '' ? `, ${name}` : name);
    });

    return (isWildcardWebHook ? '*' : desc);
  },

  createProperties() {
    const types = this.get('web_hook_event_types');
    const categories = this.get('filteredCategories');
    const groups = this.get('filteredGroups');

    return {
      payload_url: this.get('payload_url'),
      content_type: this.get('content_type'),
      secret: this.get('secret'),
      wildcard_web_hook: this.get('wildcard_web_hook'),
      verify_certificate: this.get('verify_certificate'),
      active: this.get('active'),
      web_hook_event_type_ids: Ember.isEmpty(types) ? [null] : types.map(type => type.id),
      category_ids: Ember.isEmpty(categories) ? [null] : categories.map(c => c.id),
      group_ids: Ember.isEmpty(groups) ? [null] : groups.map(c => c.id)
    };
  },

  updateProperties() {
    return this.createProperties();
  }
});

