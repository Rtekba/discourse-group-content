# frozen_string_literal: true

# name: discourse-group-content
# about: Show parts of posts only to selected groups
# version: 0.1
# authors: Rtekba

enabled_site_setting :group_content_enabled

after_initialize do
  require_dependency "pretty_text"

  # Rejestrujemy custom tag [group=name]
  PrettyText::Engine.register_markup_context do |context|
    context.register_tag("group") do |attrs, content|
      group_name = attrs[0]

      "<div class='group-content' data-group='#{group_name}'>#{content}</div>"
    end
  end

  # Przetwarzanie HTML po renderze
  PrettyText::Engine.add_preprocessor do |doc, opts|
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
          "<div class='group-content-hidden'>🔒 Ta treść jest dostępna tylko dla grupy: #{group_name}</div>"
        )
      end
    end
  end
end
