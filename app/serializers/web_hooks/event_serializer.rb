class WebHooks::EventSerializer < ApplicationSerializer
  embed :objects

  attributes :action, :version, :uuid, :url #, ...

  # no actual model yet, it's a stub
  def action
    # :topic_created to 'topic.created'
    # "posts.{created, updated, deleted, ...}"
    object[:event_type].to_s.gsub('_', '.')
  end

  def version
    ::Discourse::VERSION::STRING
  end
end

# s = WebHooks::TopicEventSerializer.new(Topic.last)
# JSON.pretty_generate(JSON.parse(s.to_json))
