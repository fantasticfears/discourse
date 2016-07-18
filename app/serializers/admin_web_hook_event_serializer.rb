class AdminWebHookEventSerializer < ApplicationSerializer
  attributes :id,
             :web_hook_id,
             :headers,
             :payload,
             :status,
             :response_headers,
             :response_body,
             :duration,
             :created_at
end
