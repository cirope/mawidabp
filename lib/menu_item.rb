class MenuItem
  include Comparable

  attr_reader :name, :order, :children, :url, :html_class, :extra_conditions,
    :exclude_from_privileges
  attr_accessor :parent

  def initialize(name = nil, options = {})
    options.assert_valid_keys(:order, :controllers, :children, :url, :class,
      :extra_conditions, :exclude_from_privileges)

    @name = name
    @order = options[:order] || 0
    @base_controllers = options[:controllers] || []
    @children = options[:children] || []
    @html_class = options[:class]
    @extra_conditions = options[:extra_conditions]
    @exclude_from_privileges = options[:exclude_from_privileges]
    @url = options[:url].kind_of?(Hash) ?
      { :action => :index }.merge(options[:url]) :
      options[:url]

    @children.each { |child| child.parent ||= self }
  end

  def <=>(other)
    other.kind_of?(MenuItem) ? self.order <=> other.order : -1
  end

  def to_s
    @translations ||= {}
    @translations[I18n.locale] ||= I18n.t(:"menu.#{self.translation_string}")
  end

  def self_and_ancestors
    unless @ancestors
      item, @ancestors = self, [self]

      @ancestors << item = item.parent while item.parent
    end
    
    @ancestors
  end

  def ancestors
    self.self_and_ancestors - [self]
  end

  def menu_name
    @menu_name ||= self.self_and_ancestors.reverse.map(&:name).join('_')
  end

  def submenu_names
    @submenu_names ||= ([self.menu_name] +
      self.children.map { |child| child.submenu_names }).flatten
  end

  def translation_string
    @translation_string ||= self.children.blank? && self.parent ?
      self.self_and_ancestors.reverse.map(&:name).join('.') :
      "#{self.self_and_ancestors.reverse.map(&:name).join('.')}_title"
  end

  def controllers
    @controllers ||= (@base_controllers.kind_of?(Array) ?
        @base_controllers : [@base_controllers]) |
      self.children.map(&:controllers).flatten.uniq
  end

  def conditions(controller, join_with_and = true)
    @conditions ||= {}

    unless @conditions["#{controller}_#{join_with_and}"]
      child_conditions = self.children.select do |child|
        child.controllers.include?(controller)
      end
      conditions = [self.extra_conditions] +
        child_conditions.map { |child| child.conditions(controller) }

      @conditions["#{controller}_#{join_with_and}"] =
        conditions.reject{|c| c.blank?}.uniq.join(
        join_with_and ? ' && ' : ' || ')
    else
      @conditions["#{controller}_#{join_with_and}"]
    end
  end
end
