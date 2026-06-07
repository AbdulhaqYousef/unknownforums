class EnablePgTrgmForSearch < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm"

    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_forum_threads_on_title_trgm
      ON forum_threads USING gin (title gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_posts_on_body_trgm
      ON posts USING gin (body gin_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_posts_on_body_trgm"
    execute "DROP INDEX IF EXISTS index_forum_threads_on_title_trgm"
    disable_extension "pg_trgm"
  end
end
