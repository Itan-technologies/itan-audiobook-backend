class ConvertContributorsToJsonb < ActiveRecord::Migration[7.1]
  def up
    # First, convert string array to JSON string, then to JSONB
    execute <<-SQL
      ALTER TABLE books 
      ALTER COLUMN contributors 
      TYPE jsonb 
      USING array_to_json(contributors)::jsonb;
    SQL
  end
  
  def down
    # Convert JSONB back to string array
    execute <<-SQL
      ALTER TABLE books 
      ALTER COLUMN contributors 
      TYPE text[] 
      USING (
        SELECT array_agg(value::text) 
        FROM jsonb_array_elements_text(contributors)
      );
    SQL
  end
end
