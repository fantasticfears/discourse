module SiteSettings
  module SlugConcern
    extend ActiveSupport::Concern

    included do
      # after_commit is tricky. This 1+ line is safer.
      after_save :switch_slugs, if: :slug_generation_method_changed?
      after_destroy :switch_slugs, if: :slug_generation_method_changed?
    end

    private

    def switch_slugs
      replace_critical_slugs
      enqueue_replacing_non_urgent_slugs
    end

    def replace_critical_slugs
      Category.find_each do |c|
        c.slug = Slug.for(c.name)
        c.save
      end
    end

    def ensure_slug
      return unless name.present?

      self.name.strip!

      if slug.present?
        # santized custom slug
        self.slug = Slug.sanitize(slug)
        errors.add(:slug, 'is already in use') if duplicate_slug?
      else
        # auto slug
        self.slug = Slug.for(name, '')
        self.slug = '' if duplicate_slug?
      end
      # only allow to use category itself id. new_record doesn't have a id.
      unless new_record?
        match_id = /^(\d+)-category/.match(self.slug)
        errors.add(:slug, :invalid) if match_id && match_id[1] && match_id[1] != self.id.to_s
      end
    end

    def enqueue_replacing_non_urgent_slugs
      # Jobs.enqueue(:replace_slug)
    end

    def slug_generation_method_changed?
      name == 'slug_generation_method' && value_changed?
    end
  end
end
