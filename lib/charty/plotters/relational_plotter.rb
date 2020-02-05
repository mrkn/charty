module Charty
  module Plotters
    class RelationalPlotter < AbstractPlotter
      def initialize(x, y, color, **options, &block)
        super

        setup_variables
        setup_color(@plot_data[:color], @palette, @color_order, @color_norm)
        # TODO: setup_size
        # TODO: setup_style
      end

      attr_accessor :color_order
      attr_accessor :color_norm

      private def setup_variables
        if x.nil? && y.niml?
          setup_variables_with_wide_form_dataset
        elsif x && y
          setup_variables_with_long_form_dataset
        else
          raise ArgumentError,
                "Either both or neither of `x` and `y` must be specified " +
                "(but try passing to `data`, which is more flexible)"
        end

        # Assign default values for missing variables
        @plot_data[:color] ||= nil
        @plot_data[:style] ||= nil
        @plot_data[:size] ||= nil
        @plot_data[:units] ||= nil

        # Determine which semantics have (some) data
        @semantics = [:x, :y]
        [:color, :style, :size].each do |name|
          @sematics << name unless empty_data?(@plot_data[name])
        end
      end

      private def setup_variables_with_wide_form_dataset
        raise NotImplementedError, "wide-form dataset is not supported"
      end

      private def setup_variables_with_long_form_dataset
        if @data
          x = @data[x] || x
          y = @data[y] || y
          color = @data[color] || color
          # TODO: color, size, style, and units
        end

        [x, y, color].each do |input|
          next if array?(input)
          raise ArgumentError,
                "Could not interpret interpret input `#{input.inspect}`"
        end

        # Extract variable names
        @x_label = x.name if x.respond_to?(:name) 
        @y_label = y.name if y.respond_to?(:name) 
        @color_label = color.name if color.respond_to?(:name) 
        # TODO: @style_label = style.name if style.respond_to?(:name) 
        # TODO: @size_label = size.name if size.respond_to?(:name) 

        # Reassemble into a Hash
        @plot_data = {
          x: x,
          y: y,
          color: color,
          # TODO: style, size, and units
        }
      end

      private def setup_color(data, palette, order, norm)
        if empty_data?(data)
          @levels = [nil]
          @limits = nil
          @norm = nil
          palette = nil
          @var_type = nil
          @cmap = nil
        else
          # Determine what kind of hue mapping we want
          @var_type = detect_semantic_type(data)

          # Override by the palette argument
          @var_type = :categorical if palette
        end

        case var_type
        when :catregorical
          @cmap = nil
          @limits = nil
          @levels, palette = categorical_to_palette(data, order, palette)
        when :numeric
          @levels, palette, @cmap, @norm = numeric_to_palette(data, order, palette, norm)
          @limits = norm.vmin, norm.vmax
        else
          # BUG
          raise RuntimeError, "BUG: must not reach here"
        end

        self.palette = palette
      end

      # Determine if data should considered numeric or categorical
      private def detect_semantic_type(data)
        if @input_format == :wide
          :categorical
        elsif array?(data) &&
              (data[0].is_a?(String) || data[0].is_a?(Symbol)) # categorical values
          :categorical
        else
          begin
            float_data = Array(data).map {|x| x.nil? ? nil : Float(x) }
            values = float_data.compact.uniq.sort
            if values == [0.0, 1.0]
              :categorical
            else
              :numeric
            end
          rescue TypeError
            :categorical
          end
        end
      end

      # Determine colors when the color variable is qualitative
      private def categorical_to_palette(data, order, palette)
        # Identify the order and name of the levels
        if order.nil?
          levels = categorical_order(data)
        else
          levels = order
        end
        n_colors = levels.length

        # Identify the set of colors to use
        case palette
        when Hash
        else
        end
      end

      # Determine colors when the color variable is quantitative
      private def numeric_to_palette(data, order, palette, norm)
      end
    end
  end
end
