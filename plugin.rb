# frozen_string_literal: true

# name: discourse-group-content
# about: Show parts of posts only to selected groups
# version: 0.3
# authors: Rtekba

enabled_site_setting :group_content_enabled

after_initialize do

  # Hook w momencie renderowania posta
  add_to_class(Post, :cook) do |raw, opts = {}|

    cooked = super(raw, opts)

    user = opts[:user]

    cooked.gsub(/<group name="(.*?)">(.*?)<\/group>/m) do
      group_name = Regexp.last_match(1)
      content = Regexp.last_match(2)

      group = Group.find_by(name: group_name)

      allowed =
        user &&
        group &&
        (user.groups.include?(group) || user.admin?)

      if allowed
        content
      else
        "<div class='group-content-hidden'>🔒 Nie masz dostępu do tego postu</div>"
      end
    end
  end

  # zamiana shortcode -> HTML (na etapie zapisu)
  Post.class_eval do
    after_save :inject_group_tags

    def inject_group_tags
      return unless raw.present?

      new_raw = raw.gsub(/\[group=(.*?)\](.*?)\[\/group\]/m) do
        group = Regexp.last_match(1)
        content = Regexp.last_match(2)

        "<group name='#{group}'>#{content}</group>"
      end

      if new_raw != raw
        update_column(:raw, new_raw)
      end
    end
  end

end
