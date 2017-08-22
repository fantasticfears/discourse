require 'rails_helper'
require 'jobs/regular/replace_slugs'

describe Jobs::ReplaceSlugs do
  describe 'changes slugs' do
    it "changes topic slugs" do
      t1 = Fabricate(:topic)
      t2 = Fabricate(:topic, slug: 'ok')
      SiteSetting.slug_generation_method = 'none'
      Jobs::ReplaceSlugs.new.execute({})
      t1.reload
      t2.reload
      expect(t1.slug).to eq 'topic'
      expect(t2.slug).to eq 'topic'
    end
  end
end
