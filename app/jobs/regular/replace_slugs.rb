module Jobs
  class ReplaceSlugs < Jobs::Base
    def execute(args)
      # QUESTION: Maybe a critical section is needed for the same job?
      Topic.find_each do |t|
        t.update_attribute(:slug, Slug.for(t.title))
      end
    end
  end
end
