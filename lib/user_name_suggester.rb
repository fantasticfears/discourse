require_dependency 'i18n_kit'

module UserNameSuggester
  GENERIC_NAMES = ['i', 'me', 'info', 'support', 'admin', 'webmaster', 'hello', 'mail', 'office', 'contact', 'team']

  module Implementation
    def suggest(name, allow_username = nil)
      return unless name.present?
      name = parse_name_from_email(name)
      find_available_username_based_on(name, allow_username)
    end

    def parse_name_from_email(name)
      if name =~ User::EMAIL
        # When 'walter@white.com' take 'walter'
        name = Regexp.last_match[1]
        # When 'me@eviltrout.com' take 'eviltrout'
        name = Regexp.last_match[2] if GENERIC_NAMES.include?(name)
      end
      name
    end

    def find_available_username_based_on(name, allow_username = nil)
      name = fix_username(name)
      i = 1
      attempt = name
      until attempt == allow_username || User.username_available?(attempt) || i > 100
        suffix = i.to_s
        max_length = User.username_length.end - suffix.length - 1
        attempt = "#{name[0..max_length]}#{suffix}"
        i += 1
      end
      until attempt == allow_username || User.username_available?(attempt) || i > 200
        attempt = SecureRandom.hex[1..SiteSetting.max_username_length]
        i += 1
      end
      attempt
    end

    def fix_username(name)
      rightsize_username(sanitize_username(name))
    end

    def sanitize_username(name)
      name = prepare_username(name)
      name = replace_confusable_with_character(name)
      name = remove_unallowed_trailing_characters(name)
      name = unifiy_special_characters(name)
      name
    end

    def prepare_username(name)
      SiteSetting.allow_unicode_username ? name : transliterate_username(name)
    end

    def transliterate_username(name)
      I18nKit.transliterate(name)
    end

    def replace_confusable_with_character(name, replacement = '_')
      name.gsub(UsernameValidator::CONFUSING_EXTENSIONS, replacement)
        .gsub(/[^\w.-]/, replacement)
    end

    def remove_unallowed_trailing_characters(name)
      name.gsub(/^\W+/, "")
        .gsub(/[^A-Za-z0-9]+$/, "")
    end

    def unifiy_special_characters(name)
      name.gsub(/[-_.]{2,}/, "_")
    end

    def rightsize_username(name)
      name = name[0, User.username_length.end]
      name = remove_unallowed_trailing_characters(name)
      name.ljust(User.username_length.begin, '1')
    end
  end

  extend Implementation
end
