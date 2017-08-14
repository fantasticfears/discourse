class CategorySearchData < ActiveRecord::Base
  include HasSearchData
end

# == Schema Information
#
# Table name: category_search_data
#
#  category_id :integer          not null, primary key
#  search_data :tsvector
#  raw_data    :text
#  locale      :text
#
# Indexes
#
#  idx_search_category  (search_data)
#
