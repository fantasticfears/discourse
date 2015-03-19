import RestrictedUserRoute from "discourse/routes/restricted-user";

export default RestrictedUserRoute.extend({
  model() {
    return Discourse.ajax("/users/two_factor_authentication.json").then(function(result) {
      console.log(result.otp ? result.otp : 'ab');
      return result.otp ? result.otp : {modules: {}};
    });
  },

  renderTemplate() {
    return this.render({ into: 'user' });
  },

  // A bit odd, but if we leave to /preferences we need to re-render that outlet
  deactivate() {
    this._super();
    this.render('preferences', { into: 'user', controller: 'preferences' });
  },

  setupController(controller, model) {
    controller.set('model', model);
    controller.set('user', this.modelFor('user'));
  }

});

