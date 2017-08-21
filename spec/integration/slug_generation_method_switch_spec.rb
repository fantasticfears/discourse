require 'rails_helper'
require_dependency 'site_settings/slug_concern'

describe "Slug will reflect based on slug_generation_method" do
  before { SiteSetting.slug_generation_method = 'encoded' }

  describe 'imediately changes important slugs' do
    it "don't change the category's custom slug or default slug" do
      c1 = Fabricate(:category, slug: 'k')
      c2 = Fabricate(:category, slug: 'another-chinese-中文', name: 'Chinese中文')
      c3 = Fabricate(:category)
      obslete_category_slug = Fabricate(:category, slug: 'chinese-中文1', name: 'Chinese中文1')
      obslete_category_slug.update_column(:slug, 'chinese-中文1')

      expect(c1.slug).to eq 'k'
      expect(c2.slug).to eq 'another-chinese-%E4%B8%AD%E6%96%87'
      expect(c3.slug).to eq "#{c3.id}-category"
      expect(c4.slug).to eq 'chinese-中文1'

      SiteSetting.slug_generation_method = 'none'
      expect(c1.slug).to eq 'k'
      expect(c2.slug).to eq 'another-chinese-%E4%B8%AD%E6%96%87'
      expect(c3.slug).to eq "#{c3.id}-category"
      expect(c4.slug).to eq 'chinese-%E4%B8%AD%E6%96%871'
    end
  end

  describe 'enqueue changes for other slugs' do
    Jobs.expects(:replace_slug).once
    SiteSetting.slug_generation_method = 'none'
  end
end