class WebHooks::TopicEventSerializer < ApplicationSerializer
  # created, auto_closed

  # better to create some mixins
  attributes :topic

  # use `embed` for example now
  # I prefer fat payload. Say we will serialize category and user with topic in such case
  # and use has_* for limiting attributes
  def topic
    object
  end
end

