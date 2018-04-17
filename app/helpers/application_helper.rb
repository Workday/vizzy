module ApplicationHelper
  def bootstrap_class_for flash_type
    {success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info"}[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible", role: 'alert') do
        concat(content_tag(:button, class: 'close', data: {dismiss: 'alert'}) do
          concat content_tag(:span, '&times;'.html_safe, 'aria-hidden' => true)
          concat content_tag(:span, 'Close', class: 'sr-only')
        end)
        concat message
      end)
    end
    nil
  end

  # Render tree structure of tests
  # Params:
  # - tests: tests arranged in tree structured hash -- tests.arrange
  def render_nested_tests(tests)
    content_tag(:ul) do
      tests.map do |test, sub_tests|
        span_tag = content_tag(:li, (test.name + render_nested_tests(sub_tests)).html_safe)
        link_to(span_tag, test_path(test))
      end.join.html_safe
    end
  end

  def breaking_word_wrap(text, *args)
    return text if text.nil?
    options = args.extract_options!
    unless args.blank?
      options[:line_width] = args[0] || 80
    end
    options.reverse_merge!(:line_width => 80)
    text = text.split(" ").collect do |word|
      word.length > options[:line_width] ? word.gsub(/(.{1,#{options[:line_width]}})/, "\\1 ") : word
    end * " "
    text.split("\n").collect do |line|
      line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end
