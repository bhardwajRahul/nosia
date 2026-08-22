class AlignChunksEmbeddingDimensions < ActiveRecord::Migration[8.0]
  def up
    dimensions = Chunk.embedding_dimensions

    # Rails' change_column silently skips the ALTER for custom vector types,
    # so issue it directly. pgvector enforces an exact dimension match on
    # insert: the column must line up with what the embedder produces or
    # every indexing run fails at save time. Rows indexed under a previous
    # width make this raise loudly — re-index those sources first.
    execute("ALTER TABLE chunks ALTER COLUMN embedding TYPE vector(#{dimensions.to_i})")

    if dimensions <= 2000
      # HNSW caps vector indexes at 2000 dimensions; wider configs stay
      # unindexed (sequential scan) rather than failing to migrate.
      add_index :chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
    end
  end

  def down
    remove_index :chunks, :embedding if index_exists?(:chunks, :embedding)
    execute("ALTER TABLE chunks ALTER COLUMN embedding TYPE vector(4096)")
  end
end
