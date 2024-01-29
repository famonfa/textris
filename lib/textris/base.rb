require 'render_anywhere'

module Textris
  class Base
    class RenderingController < RenderAnywhere::RenderingController
      layout false

      def default_url_options
        ActionMailer::Base.default_url_options || {}
      end
    end

    include RenderAnywhere
    extend Textris::Delay::Sidekiq

    class << self
      def deliveries
        ::Textris::Delivery::Test.deliveries
      end

      def with_defaults(options)
        defaults.merge(options)
      end

      def defaults
        @defaults ||= superclass.respond_to?(:defaults) ? superclass.defaults.dup : {}
      end

      protected

      def default(options)
        defaults.merge!(options)
      end

      private

      def method_missing(method_name, *args)
        new(method_name, *args).call_action
      end

      def respond_to_missing?(method, *args)
        public_instance_methods(true).include?(method) || super
      end
    end

    def initialize(action, *args)
      @action = action
      @args   = args
    end

    def call_action
      send(@action, *@args)
    end

    def render_content
      set_instance_variables_for_rendering

      render(:template => template_name, :formats => ['text'], :locale => @locale)
    end

    protected

    def text(options)
      @locale = options[:locale] || I18n.locale

      options = self.class.with_defaults(options)
      options.merge!(
        :texter     => self.class,
        :action     => @action,
        :args       => @args,
        :content    => options[:body].is_a?(String) ? options[:body] : nil,
        :renderer   => self)

      ::Textris::Message.new(options)
    end

    private

    def template_name
      class_name  = self.class.to_s.underscore.sub('texter/', '')
      action_name = @action

      "#{class_name}/#{action_name}"
    end

    def set_instance_variables_for_rendering
      instance_variables.each do |var|
        set_instance_variable(var.to_s.sub('@', ''), instance_variable_get(var))
      end
    end
  end
end


# require 'action_view'

# module Textris
#   class Base
#     include ActionView::Context
#     include ActionView::Helpers::TagHelper
#     include ActionView::Helpers::UrlHelper

#     class << self
#       def deliveries
#         ::Textris::Delivery::Test.deliveries
#       end

#       def with_defaults(options)
#         defaults.merge(options)
#       end

#       def defaults
#         @defaults ||= superclass.respond_to?(:defaults) ? superclass.defaults.dup : {}
#       end

#       protected

#       def default(options)
#         defaults.merge!(options)
#       end

#       private

#       def method_missing(method_name, *args)
#         new(method_name, *args).call_action
#       end

#       def respond_to_missing?(method, *args)
#         public_instance_methods(true).include?(method) || super
#       end
#     end

#     def initialize(action, *args)
#       @action = action
#       @args   = args
#     end

#     def call_action
#       send(@action, *@args)
#     end

#     def render_content
#       set_instance_variables_for_rendering

#       # Render the template using Action View
#       template = File.read("#{Rails.root}/app/views/#{template_name}.text.erb")
#       renderer = ActionView::Base.new(ActionController::Base.view_paths, {})
#       rendered_content = renderer.render(inline: template)

#       rendered_content
#     end

#     protected

#     def text(options)
#       options = self.class.with_defaults(options)
#       options.merge!(
#         texter: self.class,
#         action: @action,
#         args: @args,
#         content: options[:body].is_a?(String) ? options[:body] : nil,
#         renderer: self
#       )

#       ::Textris::Message.new(options)
#     end

#     private

#     def template_name
#       class_name  = self.class.to_s.underscore.sub('texter/', '')
#       action_name = @action

#       "#{class_name}/#{action_name}"
#     end

#     def set_instance_variables_for_rendering
#       instance_variables.each do |var|
#         instance_variable_set(var.to_s.sub('@', ''), instance_variable_get(var))
#       end
#     end
#   end
# end
