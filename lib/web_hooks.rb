# require first: require_dependency 'web_hooks'

module WebHooks
  # I don't think there will be 1k+ webhooks...
  @_hooks = {
    topic_created: [1, 2] # webhooks model id
  }

  # load when Discourse starts by WebHooks.where(active: )
  def self.register_hooks
    # query from model
    # return a array of WebHooks models id
  end

  def self.clear_hooks
  end

  def self.default_serialization_options
    {}
  end

  # It will be more like active_record objects
  def self.where(type)
    @_hooks.fetch(type.to_sym)
  end
end
