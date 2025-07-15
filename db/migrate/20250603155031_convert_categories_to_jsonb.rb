class ConvertCategoriesToJsonb < ActiveRecord::Migration[7.1]
  def up
    # Convert string array to JSONB
    execute <<-SQL
      ALTER TABLE books 
      ALTER COLUMN categories 
      TYPE jsonb 
      USING array_to_json(categories)::jsonb;
    SQL
  end
  
  def down
    # Convert JSONB back to string array
    execute <<-SQL
      ALTER TABLE books 
      ALTER COLUMN categories 
      TYPE text[] 
      USING (
        SELECT array_agg(value::text) 
        FROM jsonb_array_elements_text(categories)
      );
    SQL
  end
end
