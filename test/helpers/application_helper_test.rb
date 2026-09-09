require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # LLM output and crawled pages are attacker-influenceable (prompt injection,
  # hostile pages). Commonmarker's defaults are the first line of defense; this
  # sanitizer is the second, so a library default flip can't reopen stored XSS.
  test "strips script and inline handlers from rendered markdown" do
    html = '<p>safe</p><script>alert(1)</script><img src="x" onerror="alert(2)">'

    out = sanitized_markdown(html)

    assert_includes out, "<p>safe</p>"
    assert_not_includes out, "script"
    assert_not_includes out, "onerror"
  end

  test "neutralizes javascript urls but keeps ordinary links" do
    html = '<a href="javascript:alert(1)">bad</a><a href="https://ok.example">good</a>'

    out = sanitized_markdown(html)

    assert_includes out, 'href="https://ok.example"'
    assert_not_includes out.downcase, "javascript:"
  end

  test "preserves the markdown surface users rely on" do
    html = "<h2>Title</h2><ul><li><strong>b</strong></li></ul>" \
      "<pre><code>x = 1</code></pre>" \
      "<table><thead><tr><th>H</th></tr></thead><tbody><tr><td>d</td></tr></tbody></table>" \
      '<input type="checkbox" disabled checked>' \
      '<img src="https://img.example/a.png" alt="pic">'

    out = sanitized_markdown(html)

    %w[<h2> <ul><li><strong> <pre><code> <table> <input type="checkbox" <img src=].each do |fragment|
      assert_includes out, fragment, "expected #{fragment} to survive sanitization"
    end
  end
end
