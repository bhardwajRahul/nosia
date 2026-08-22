module ApplicationHelper
  # Second layer over Commonmarker for every rendered markdown surface (LLM
  # output, streamed output, crawled pages). Commonmarker already escapes raw
  # HTML by default — this guards against a config flip or gem upgrade
  # silently reopening stored XSS from prompt-injected or hostile content.
  SANITIZED_MARKDOWN_TAGS = %w[
    p h1 h2 h3 h4 h5 h6 ul ol li a strong em b i code pre blockquote
    table thead tbody tr th td br hr del ins sub sup mark dl dt dd kbd
    span input img
  ].freeze
  SANITIZED_MARKDOWN_ATTRIBUTES = %w[href src alt title class id colspan rowspan type disabled checked aria-hidden].freeze

  def sanitized_markdown(html)
    sanitize html, tags: SANITIZED_MARKDOWN_TAGS, attributes: SANITIZED_MARKDOWN_ATTRIBUTES
  end

  def registrations_allowed?
    ActiveModel::Type::Boolean.new.cast(ENV["REGISTRATIONS_ALLOWED"])
  end
end
