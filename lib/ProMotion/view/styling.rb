motion_require '../extensions/conversions'

module ProMotion
  module Styling
    include Conversions

    def set_attributes(element, args = {})
      args = get_attributes_from_symbol(args)
      args.each { |k, v| set_attribute(element, k, v) }
      element
    end

    def set_attribute(element, k, v)
      return element unless element

      if v.is_a?(Hash) && element.respond_to?(k)
        sub_element = element.send(k)
        set_attributes(sub_element, v) if sub_element
      elsif element.respond_to?("#{k}=")
        element.send("#{k}=", v)
      elsif v.is_a?(Array) && element.respond_to?("#{k}") && element.method("#{k}").arity == v.length
        element.send("#{k}", *v)
      else
        # Doesn't respond. Check if snake case.
        if k.to_s.include?("_")
          set_attribute(element, objective_c_method_name(k), v)
        end
      end
      element
    end

    def set_easy_attributes(parent, element, args={})
      attributes = {}

      if args[:resize]
        attributes[:autoresizingMask]  = UIViewAutoresizingNone
        args[:resize].each { |r| attributes[:autoresizingMask] |= map_resize_symbol(r) }
      end

      args[:left] = args.delete(:x) if args[:x]
      args[:top] = args.delete(:y) if args[:y]
      if [:left, :top, :width, :height].select{ |a| args[a] && args[a] != :auto }.length == 4
        attributes[:frame] = CGRectMake(args[:left], args[:top], args[:width], args[:height])
      end

      set_attributes element, attributes
      element
    end

    def content_max(view, mode = :height)
      return 0 if view.subviews.empty?

      sizes = view.subviews.map do |sub_view|
        if sub_view.isHidden
          0
        elsif mode == :height
          sub_view.frame.origin.y + sub_view.frame.size.height
        else
          sub_view.frame.origin.x + sub_view.frame.size.width
        end
      end

      sizes.max
    end

    def content_height(view)
      content_max(view, :height)
    end

    def content_width(view)
      content_max(view, :width)
    end

    def closest_parent(type, this_view = nil)
      # iterate up the view hierarchy to find the parent element of "type" containing this view
      this_view ||= view_or_self.superview
      while this_view != nil do
        return this_view if this_view.is_a? type
        this_view = this_view.superview
      end
      nil
    end

    def add(element, attrs = {})
      add_to view_or_self, element, attrs
    end
    alias :add_element :add
    alias :add_view :add

    def remove(elements)
      Array(elements).each(&:removeFromSuperview)
    end
    alias :remove_element :remove
    alias :remove_view :remove

    def add_to(parent_element, elements, attrs = {})
      attrs = get_attributes_from_symbol(attrs)
      Array(elements).each do |element|
        parent_element.addSubview element
        if attrs && attrs.length > 0
          set_attributes(element, attrs)
          set_easy_attributes(parent_element, element, attrs)
        end
      end
      elements
    end

    def view_or_self
      self.respond_to?(:view) ? self.view : self
    end

    # These three color methods are stolen from BubbleWrap.
    def rgb_color(r,g,b)
      rgba_color(r,g,b,1)
    end

    def rgba_color(r,g,b,a)
      r,g,b = [r,g,b].map { |i| i / 255.0}
      UIColor.colorWithRed(r, green: g, blue:b, alpha:a)
    end

    def hex_color(str)
      hex_color = str.gsub("#", "")
      case hex_color.size
      when 3
        colors = hex_color.scan(%r{[0-9A-Fa-f]}).map{ |el| (el * 2).to_i(16) }
      when 6
        colors = hex_color.scan(%r<[0-9A-Fa-f]{2}>).map{ |el| el.to_i(16) }
      else
        raise ArgumentError
      end

      if colors.size == 3
        rgb_color(colors[0], colors[1], colors[2])
      else
        raise ArgumentError
      end
    end

    protected

    def get_attributes_from_symbol(attrs)
      return attrs if attrs.is_a?(Hash)
      PM.logger.error "#{attrs} styling method is not defined" unless self.respond_to?(attrs)
      new_attrs = send(attrs)
      PM.logger.error "#{attrs} should return a hash" unless new_attrs.is_a?(Hash)
      new_attrs
    end

    def map_resize_symbol(symbol)
      @_resize_symbols ||= {
        left:     UIViewAutoresizingFlexibleLeftMargin,
        right:    UIViewAutoresizingFlexibleRightMargin,
        top:      UIViewAutoresizingFlexibleTopMargin,
        bottom:   UIViewAutoresizingFlexibleBottomMargin,
        width:    UIViewAutoresizingFlexibleWidth,
        height:   UIViewAutoresizingFlexibleHeight
      }
      @_resize_symbols[symbol] || symbol
    end

  end
end
