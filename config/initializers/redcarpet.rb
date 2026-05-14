module MarkdownHelper
  RENDERER = Redcarpet::Render::HTML.new(
    filter_html:     true,
    hard_wrap:       true,
    link_attributes: { target: "_blank", rel: "noopener noreferrer" }
  )

  MARKDOWN = Redcarpet::Markdown.new(
    RENDERER,
    autolink:            true,
    tables:              true,
    fenced_code_blocks:  true,
    strikethrough:        true,
    superscript:         true,
    highlight:           true,
    space_after_headers: true,
    no_intra_emphasis:   true
  )

  def self.render(text)
    MARKDOWN.render(text.to_s).html_safe
  end
end
