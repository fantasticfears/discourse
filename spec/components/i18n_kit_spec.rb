# encoding: utf-8

require 'rails_helper'

describe I18nKit do
  describe '#transliterate' do
    it 'transliterates string to ascii' do
      expect(I18nKit.transliterate("Jørn")).to eq('Jorn')
    end

    it 'transliterates chinese to ascii' do
      expect(I18nKit.transliterate('中文')).to eq('zhongwen')
    end
  end
end
