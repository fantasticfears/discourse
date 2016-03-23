class WebHookEvent < ActiveRecord::Base

end

# == Schema Information
#
# Table name: web_hook_events
#
#  id               :uuid             not null, primary key
#  url              :string           not null
#  type             :string           not null # a single type
#  web_hook_id      :integer
#  status           :integer
#  retries          :integer          default(0)
#  request_header   :string
#  request_payload  :string
#  response_code    :integer
#  response_header  :string
#  response_payload :string
#  completion_time  :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
