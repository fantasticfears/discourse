# This module contains convenient methods for Unicode related functions

require 'icu'

# Named so that it won't be confused with i18n gem
module I18nKit
  class IcuService
    def initialize
      @transliterators = {}
    end

    def transliterator_for(id)
      @transliterators[id] ||= ICU::Transliterator.new(id)
    end

    def spoof_checker
      @spoof_checker ||= ICU::SpoofChecker.new
    end
  end

  module Base
    def service
      @service ||= I18nKit::IcuService.new
    end

    def transliterate(string, transliterator_id = 'Any-Latin; Latin-Ascii')
      service.transliterator_for(transliterator_id).transliterate(string)
    end

    # returns true when the string is good.
    def spoof_check(string)
      (service.spoof_checker.check(string) & ICU::SpoofChecker::Checks::ALL_CHECKS) == 0
    end
  end

  extend Base
end
