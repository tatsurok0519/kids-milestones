class AddUniqueIndexToAchievements < ActiveRecord::Migration[7.1]
  # PostgreSQL の並行 index 作成/削除に対応するため、トランザクションを無効化
  disable_ddl_transaction!

  INDEX_NAME = "index_achievements_on_child_id_and_milestone_id"
  COLUMNS    = [:child_id, :milestone_id]

  def up
    # すでに「同じ列のユニーク index」が存在するなら何もしない
    if unique_index_exists_for?(table: :achievements, columns: COLUMNS)
      return
    end

    # まず重複行を掃除（重複があるとユニークindexの作成に失敗します）
    cleanup_duplicates!

    # 既存の非ユニーク index を安全に外す（名前あり／なし両対応）
    if index_exists?(:achievements, COLUMNS, name: INDEX_NAME)
      remove_index :achievements, **rm_opts(name: INDEX_NAME)
    elsif index_exists?(:achievements, COLUMNS)
      remove_index :achievements, **rm_opts(column: COLUMNS)
    end

    # ユニーク index を作成（PostgreSQL では concurrently）
    add_index :achievements, COLUMNS, unique: true, name: INDEX_NAME, **add_opts
  end

  def down
    # ユニーク index を外す
    if index_exists?(:achievements, COLUMNS, unique: true, name: INDEX_NAME)
      remove_index :achievements, **rm_opts(name: INDEX_NAME)
    end

    # 非ユニーク index を戻す（存在しなければ作成）
    add_index :achievements, COLUMNS, name: INDEX_NAME unless index_exists?(:achievements, COLUMNS, name: INDEX_NAME)
  end

  private

  def add_opts
    postgresql? ? { algorithm: :concurrently } : {}
  end

  def rm_opts(name: nil, column: nil)
    opts = {}
    opts[:name]   = name   if name
    opts[:column] = column if column
    opts[:algorithm] = :concurrently if postgresql?
    opts
  end

  def postgresql?
    connection.adapter_name.downcase.include?("postgres")
  end

  # すでに目的の“ユニークindex(同じ列集合)”があるかどうかを厳密にチェック（名前は不問）
  def unique_index_exists_for?(table:, columns:)
    cols_sorted = columns.map(&:to_s).sort
    connection.indexes(table).any? { |idx| idx.unique && idx.columns.sort == cols_sorted }
  end

  # 重複 (child_id, milestone_id) を除去して最古の1件だけ残す
  # どのDBでも動くように SQL + Ruby で実装
  def cleanup_duplicates!
    dup_groups = connection.exec_query(<<~SQL)
      SELECT child_id, milestone_id, MIN(id) AS keep_id, COUNT(*) AS cnt
      FROM achievements
      GROUP BY child_id, milestone_id
      HAVING COUNT(*) > 1
    SQL

    dup_groups.each do |row|
      child_id    = row["child_id"].to_i
      milestone_id= row["milestone_id"].to_i
      keep_id     = row["keep_id"].to_i

      # 残す行以外を削除
      connection.execute <<~SQL
        DELETE FROM achievements
        WHERE child_id = #{child_id}
          AND milestone_id = #{milestone_id}
          AND id <> #{keep_id}
      SQL
    end
  end
end