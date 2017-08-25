class Node
  attr_accessor :parent
  attr_accessor :next_sibling
  attr_reader :children

  def last_child
    return nil if first_child.nil?

    first_child.last_sibling
  end

  def last_sibling
    return self if last_sibling?

    next_sibling.last_sibling
  end

  def last_sibling?
    next_sibling.nil?
  end

  def leaf_node?
    children.blank?
  end

  def root_node?
    parent.nil?
  end

  def last_node?
    next_node.nil?
  end

  def next_node
    return first_child unless leaf_node?
    return next_sibling unless last_sibling?
    return parent.next_sibling unless root_node?
  end

  def first_child
    children
      .tap { |children| children.first.parent = self }
      .inject { |memo, next_child| memo.add_sibling! next_child }
  end

  def add_sibling!(node)
    last_sibling.next_sibling = node
    node.parent = parent
    self
  end
  alias_method :<<, :add_sibling!
end
