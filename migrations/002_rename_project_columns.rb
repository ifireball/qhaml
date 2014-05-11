Sequel.migration do
  change do
    alter_table(:projects) do
      rename_column :page_language, :page_format
      rename_column :script_language, :script_format
      rename_column :style_language, :style_format
    end
  end
end

