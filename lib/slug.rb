# encoding: utf-8

module Slug
  CHAR_FILTER_REGEXP = /[:\/\?#\[\]@!\$&'\(\)\*\+,;=_\.~%\\`^\s|\{\}"<>]+/ # :/?#[]@!$&'()*+,;=_.~%\`^|{}"<>

  def self.for(string, fallback: 'topic')
    slug =
      case (SiteSetting.slug_generation_method || :ascii).to_sym
      when :ascii then self.ascii_generator(string)
      when :encoded then self.encoded_generator(string)
      when :none then self.none_generator(string)
      end
    # Reject slugs that only contain numbers, because they would be indistinguishable from id's.
    slug = self.normalize_slug(slug)
    slug.blank? ? fallback : slug
  end

  def self.sanitize(string)
    encoded_generator(string)
  end

  nonascii = (0x80..0xff).collect { |c| c.chr }.join
  NONASCII = /([#{Regexp.escape(nonascii)}])/n

  private

  def self.normalize_slug(slug)
    slug = (slug =~ /[^\d]/ ? slug.encode('UTF-8') : '')
    self.fallback_if_too_long(slug)
  end

  def self.ascii_generator(string)
    string = string
      .tr("'", "")
      .parameterize
      .tr("_", "-")
  end

  def self.encoded_generator(string)
    # This generator will sanitize almost all special characters,
    # including reserved characters from RFC3986.
    # See also URI::REGEXP::PATTERN.
    string = string.strip
      .gsub(/\s+/, '-')
      .gsub(CHAR_FILTER_REGEXP, '')
      .squeeze('-') # squeeze continuous dashes to prettify slug
      .gsub(/\A-+|-+\z/, '') # remove possible trailing and preceding dashes
      .downcase
    self.escape_to_ascii(string)
  end

  def self.none_generator(string)
    ''
  end

  def self.escape_to_ascii(str)
    str = str.b
    str.gsub!(NONASCII) { "%%%02X" % $1.ord }
    str = str.encode(Encoding::UTF_8)
    str
  end

  def self.fallback_if_too_long(string)
    # TODO: This magic number only defines in SQL schema for slugs
    if string.length >= 255
      ''
    else
      string
    end
  end
end
