require 'ostruct'
class GroupExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag


  def self.applicable_to?(object)
    return false if object.class.name == 'ActiveRecord::Relation'
    object.class.name == 'Group' || object.class.base_class.name == 'Group'
  end

  def type_name
    "#{type}, #{type.class}"
  end

  def possible_children_options
    types = __getobj__.class.possible_children.collect(&:model_name)
    context.options_from_collection_for_select(types, :to_s, :human)
  end

  def attributes
    cls = __getobj__.class
    cls.attribute_names.select { |name| cls.attr_used?(name) }
  end


  private
  def attrs_for_remote
    url = context.fields_groups_path(group: { parent_id: parent.id })
    url = URI.unescape(url)
    { data: { remote: true, replace: true, url: url }  } 
  end

  def type_as_sym
    type && type.split('::').last.downcase.to_sym
  end

end
