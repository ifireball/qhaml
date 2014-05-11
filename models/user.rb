class User < Sequel::Model
  plugin TimedModel
  many_to_one :last_project, :class => :Project
  one_to_many :projects
  one_to_many :saved_projects, :clone => :projects, 
    :conditions => { :temporary => false }
  def save_project(project)
    saved = saved_projects_dataset.where(:name => project.name).first || 
      Project.new(:temporary => false, :user => self)
    saved.set_fields_from(project)
    saved.save
  end
end

