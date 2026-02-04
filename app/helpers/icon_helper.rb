# frozen_string_literal: true

module IconHelper
  # Render an SVG icon from the sprite
  #
  # Usage:
  #   icon('home')                          # Icon with default size (20px)
  #   icon('check', size: 16)               # Small icon
  #   icon('alert', size: 24, class: 'rp-icon--primary')
  #   icon('menu', aria_label: 'Open menu') # Icon button with label
  #
  # @param name [String] Icon identifier (without 'icon-' prefix)
  # @param size [Integer] Icon width/height in pixels (default: 20)
  # @param css_class [String] Additional CSS classes
  # @param aria_label [String] ARIA label for icon-only buttons
  # @param aria_hidden [Boolean] Whether icon is hidden from screen readers
  # @return [ActiveSupport::SafeString] SVG element
  def icon(name, size: 20, css_class: "", aria_label: nil, aria_hidden: nil)
    # Determine if icon should be hidden from screen readers
    # Default: hidden if no aria_label, visible if aria_label provided
    aria_hidden = aria_label.blank? if aria_hidden.nil?

    # Build SVG element
    content_tag :svg,
      class: css_class_for_icon(css_class, size),
      width: size,
      height: size,
      viewBox: "0 0 24 24",
      'aria-label': aria_label,
      'aria-hidden': aria_hidden,
      role: aria_label ? "img" : nil do
      content_tag :use, nil, 'href': "#icon-#{name}"
    end
  end

  # Helper method to build CSS classes for icons
  #
  # @param custom_class [String] Additional classes from user
  # @param size [Integer] Icon size in pixels
  # @return [String] Combined CSS classes
  private def css_class_for_icon(custom_class, size)
    base_class = "rp-icon"
    size_class = icon_size_class(size)

    [ base_class, size_class, custom_class ].compact.join(" ")
  end

  # Map pixel sizes to CSS modifier classes
  #
  # @param size [Integer] Icon size in pixels
  # @return [String] CSS size modifier class
  private def icon_size_class(size)
    case size
    when 16
      "rp-icon--sm"
    when 20
      nil # default, no modifier needed
    when 24
      "rp-icon--md"
    when 32
      "rp-icon--lg"
    else
      nil
    end
  end

  # Render an icon button (icon + aria-label)
  #
  # Usage:
  #   icon_button('menu', label: 'Open menu', path: '#')
  #   icon_button('delete', label: 'Delete item', method: :delete, confirm: true)
  #
  # @param icon_name [String] Icon identifier
  # @param label [String] Aria-label for the button
  # @param size [Integer] Icon size
  # @param button_class [String] CSS classes for button
  # @param html_options [Hash] Additional options passed to button_to or link_to
  # @return [ActiveSupport::SafeString] Button element
  def icon_button(icon_name, label:, size: 20, button_class: "rp-btn rp-btn--ghost rp-btn--sm", **html_options)
    # Default to button_to unless href/path provided
    if html_options[:href] || html_options[:path]
      link_to_icon_button(icon_name, label, size, button_class, html_options)
    else
      button_to_icon_button(icon_name, label, size, button_class, html_options)
    end
  end

  # Create icon + text button
  #
  # Usage:
  #   icon_with_text('check', 'Submit Assessment')
  #   icon_with_text('alert', 'Warning', size: 16)
  #
  # @param icon_name [String] Icon identifier
  # @param text [String] Button text
  # @param size [Integer] Icon size
  # @param button_class [String] CSS classes
  # @return [ActiveSupport::SafeString] Button with icon and text
  def icon_with_text(icon_name, text, size: 16, button_class: "rp-btn rp-btn--primary")
    button_tag class: button_class, type: "button" do
      concat(icon(icon_name, size: size, aria_hidden: true))
      concat(" ")
      concat(text)
    end
  end

  private

  # Render icon as a link button
  def link_to_icon_button(icon_name, label, size, button_class, html_options)
    href = html_options.delete(:href) || html_options.delete(:path)
    link_to(href, class: button_class, aria_label: label, **html_options) do
      icon(icon_name, size: size, aria_hidden: true)
    end
  end

  # Render icon as a form button
  def button_to_icon_button(icon_name, label, size, button_class, html_options)
    button_tag(class: button_class, aria_label: label, **html_options) do
      icon(icon_name, size: size, aria_hidden: true)
    end
  end
end
