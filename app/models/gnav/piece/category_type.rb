# encoding: utf-8
class Gnav::Piece::CategoryType < Cms::Piece
  LAYER_OPTIONS = [['下層のカテゴリすべて', 'descendants'], ['該当カテゴリのみ', 'self']]

  default_scope where(model: 'Gnav::CategoryType')

  def layer
    setting_value(:layer).presence || LAYER_OPTIONS.first.last
  end

  def content
    Gnav::Content::MenuItem.find(super)
  end

  def category_types
    content.category_types
  end

  def category_types_for_option
    category_types.map {|ct| [ct.title, ct.id] }
  end

  def category_type
    category_types.find_by_id(setting_value(:category_type_id))
  end

  def categories
    unless category_type
      return category_types.inject([]) {|result, ct|
                 result | ct.root_categories.inject([]) {|r, c| r | c.descendants }
               }
    end

    if (category_id = setting_value(:category_id)).present?
      if layer == 'descendants'
        category_type.categories.find_by_id(category_id).try(:descendants) || []
      else
        category_type.categories.where(id: category_id)
      end
    else
      category_type.root_categories.inject([]) {|r, c| r | c.descendants }
    end
  end

  def public_categories
    unless category_type
      return category_types.inject([]) {|result, ct|
                 result | ct.public_root_categories.inject([]) {|r, c| r | c.public_descendants }
               }
    end

    if (category_id = setting_value(:category_id)).present?
      if layer == 'descendants'
        category_type.public_categories.find_by_id(category_id).try(:public_descendants) || []
      else
        category_type.public_categories.where(id: category_id)
      end
    else
      category_type.public_root_categories.inject([]) {|r, c| r | c.public_descendants }
    end
  end

  def category
    return nil if categories.empty?

    if categories.respond_to?(:find_by_id)
      categories.find_by_id(setting_value(:category_id))
    else
      categories.detect {|c| c.id.to_s == setting_value(:category_id) }
    end
  end

  def categorize_docs(docs)
    return docs unless category_type

    docs.select do |doc|
      category_ids = (doc.respond_to?(:category_ids) ? doc.category_ids : doc.categories.map(&:id))
      !(category_ids & self.categories.map(&:id)).empty?
    end
  end
end
