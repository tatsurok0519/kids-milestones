module NavigationHelper
  # 現在ページなら .is-active を付ける
  def nav_link_to(name = nil, options = nil, **html_options, &block)
    active = current_page?(options)
    classes = [html_options[:class], ("is-active" if active)].compact.join(" ")
    link_to(name, options, **html_options.merge(class: classes), &block)
  end

  # パンくずを配列で描画
  # 例: breadcrumbs([["ダッシュボード", dashboard_path], ["子ども", children_path], ["編集", nil]])
  def breadcrumbs(trail)
    return if trail.blank?
    content_tag(:nav, aria: { label: "breadcrumb" }, class: "breadcrumbs") do
      safe_join(
        trail.each_with_index.map do |(label, path), i|
          last = (i == trail.length - 1)
          content_tag(:span) do
            if path && !last
              link_to(label, path, class: "crumb-link")
            else
              content_tag(:span, label, class: "crumb-current")
            end
          end
        end,
        content_tag(:span, "›", class: "crumb-sep") # セパレータ
      )
    end
  end
end