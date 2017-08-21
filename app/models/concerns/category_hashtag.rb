module CategoryHashtag
  extend ActiveSupport::Concern

  SEPARATOR = ":".freeze

  class_methods do
    def query_from_hashtag_slug(category_slug)
      parent_slug, child_slug = category_slug.split(SEPARATOR, 2)

      parent_slug = Slug.sanitize(parent_slug)
      category = Category.where(slug: parent_slug, parent_category_id: nil)

      if child_slug
        child_slug = Slug.sanitize(child_slug)
        Category.where(slug: child_slug, parent_category_id: category.pluck(:id).first).first
      else
        category.first
      end
    end
  end

  def hashtag_slug
    full_slug(SEPARATOR)
  end
end
