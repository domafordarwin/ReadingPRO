# frozen_string_literal: true

class StyleguideController < ApplicationController
  # Require authentication to view style guide
  before_action :require_login

  layout 'styleguide'

  # GET /styleguide
  def index
    @categories = [
      { name: 'Overview', path: 'overview', icon: 'book' },
      { name: 'Colors', path: 'colors', icon: 'palette' },
      { name: 'Typography', path: 'typography', icon: 'type' },
      { name: 'Spacing', path: 'spacing', icon: 'layout' },
      { name: 'Shadows', path: 'shadows', icon: 'shadow' },
      { name: 'Buttons', path: 'buttons', icon: 'button' },
      { name: 'Forms', path: 'forms', icon: 'input' },
      { name: 'Cards', path: 'cards', icon: 'card' },
      { name: 'Badges', path: 'badges', icon: 'tag' },
      { name: 'Tables', path: 'tables', icon: 'table' },
      { name: 'Modals', path: 'modals', icon: 'modal' },
      { name: 'Tooltips', path: 'tooltips', icon: 'info' },
      { name: 'Toasts', path: 'toasts', icon: 'notification' },
      { name: 'Icons', path: 'icons', icon: 'icon' },
      { name: 'Navigation', path: 'navigation', icon: 'menu' },
      { name: 'States', path: 'states', icon: 'state' }
    ]
  end

  # GET /styleguide/:id
  def show
    @component = params[:id]
    @categories = load_categories

    # Verify component exists
    unless valid_component?(@component)
      redirect_to styleguide_path, alert: "Component '#{@component}' not found"
      return
    end

    render "styleguide/#{@component}"
  rescue ActionView::MissingTemplate
    redirect_to styleguide_path, alert: "Component template not found: #{@component}"
  end

  private

  def load_categories
    [
      { name: 'Overview', path: 'overview', icon: 'book' },
      { name: 'Colors', path: 'colors', icon: 'palette' },
      { name: 'Typography', path: 'typography', icon: 'type' },
      { name: 'Spacing', path: 'spacing', icon: 'layout' },
      { name: 'Shadows', path: 'shadows', icon: 'shadow' },
      { name: 'Buttons', path: 'buttons', icon: 'button' },
      { name: 'Forms', path: 'forms', icon: 'input' },
      { name: 'Cards', path: 'cards', icon: 'card' },
      { name: 'Badges', path: 'badges', icon: 'tag' },
      { name: 'Tables', path: 'tables', icon: 'table' },
      { name: 'Modals', path: 'modals', icon: 'modal' },
      { name: 'Tooltips', path: 'tooltips', icon: 'info' },
      { name: 'Toasts', path: 'toasts', icon: 'notification' },
      { name: 'Icons', path: 'icons', icon: 'icon' },
      { name: 'Navigation', path: 'navigation', icon: 'menu' },
      { name: 'States', path: 'states', icon: 'state' }
    ]
  end

  def valid_component?(name)
    valid_components = %w[
      overview colors typography spacing shadows buttons forms cards badges
      tables modals tooltips toasts icons navigation states
    ]
    valid_components.include?(name)
  end
end
