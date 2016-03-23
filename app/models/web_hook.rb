class WebHook < ActiveRecord::Base

end

# == Schema Information
#
# Table name: web_hooks
#
#  id                       :integer          not null, primary key
#  url                      :string           not null
#  type                     :string           not null  # an array of type, enum or string?
#  content_type             :integer          default(0), not null
#  secret                   :string
#  verify_tls_certification :boolean          default(TRUE), not null
#  active                   :boolean          default(TRUE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
