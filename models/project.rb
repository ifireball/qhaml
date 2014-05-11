class Project < Sequel::Model
  plugin TimedModel
  many_to_one :user
  class << self
    def editable_columns
      @@editable_columns ||= %w{
        page_src page_format script_src script_format style_src style_format name
      }.map(&:to_sym)
    end
  end
  def set_fields_from(other_project)
    set_fields other_project.to_hash, Project.editable_columns, :missing => :skip
  end
  def update_fields_from(other_project)
    update_fields other_project.to_hash, Project.editable_columns, :missing => :skip
  end
end

