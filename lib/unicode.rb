# This module contains convenient methods for Unicode related functions

require 'icu'

module Unicode
  def transliterate(string)
    @transliterator ||= ICU::Transliterator.new('Any-English-Ascii')
    @transliterator.transliterate(string)
  end

  def spoof_check(string)
    @spoof_checker ||= ICU::SpoofChecker.new
    @spoof_checker.check(string) & ICU::SpoofChecker::Checks::ALL_CHECKS == 0
  end
end
