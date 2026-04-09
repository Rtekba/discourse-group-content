# frozen_string_literal: true

# name: discourse-group-content
# about: Show parts of posts only to selected groups
# version: 0.2
# authors: Rtekba

enabled_site_setting :group_content_enabled

after_initialize do
  require_dependency "pretty_text"

  # Zamienia [group=xxx] na HTML
  PrettyText.add_preprocessor do |text, opts|
    text.gsub(/\[group=(.*?)\](.*?)\[\/group\]/m) do
      group = Regexp.last_match(1)
      content = Regexp.last_match(2)

      "<div class='group-content' data-group='#{group}'>#{content}</div>"
    end
  end

  # Ukrywa content jeśli user nie ma dostępu
  PrettyText.add_post_processor do |doc, opts|
    user = opts[:user]

    doc.css(".group-content").each do |node|
      group_name = node["data-group"]
      group = Group.find_by(name: group_name)

      allowed =
        user &&
        group &&
        (user.groups.include?(group) || user.admin?)

      unless allowed
        node.replace(
          "<div class='group-content-hidden'>🔒 Post widoczny tylko dla grupy, której członkiem nie jesteś.</div>"
        )
      end
    end
  end
end
