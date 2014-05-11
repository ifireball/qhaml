Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name, :size => 64, :null => false, :unique => true
      String :password, :size => 64, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      Integer :last_project_id, :null => false
    end
    create_table(:projects) do
      primary_key :id
      Integer :user_id, :null => false, :index => true
      String :name, :size => 256, :null => false, :index => true
      TrueClass :temporary, :null => false, :default => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      String :page_src, :text => true, :null => false, :default => ""
      String :page_language, :size => 64, :null => false, :default => 'HTML'
      String :script_src, :text => true, :null => false, :default => ""
      String :script_language, :size => 64, :null => false, :default => 'Javascript'
      String :style_src, :text => true, :null => false, :default => ""
      String :style_language, :size => 64, :null => false, :default => 'CSS'
    end
  end
end

