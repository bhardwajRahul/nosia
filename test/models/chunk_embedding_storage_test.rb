require "test_helper"

class ChunkEmbeddingStorageTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "ces@example.com", password: "testpassword123")
    @account = Account.create!(name: "CES Account", owner: @user)
    @website = @account.websites.create!(url: "https://ces.example")
  end

  # pgvector enforces an exact dimension match on insert. The column must line
  # up with the dimensions the embedder actually produces
  # (EMBEDDING_DIMENSIONS, defaulting to 768), otherwise every indexing run
  # fails at save time.
  test "chunks accept embeddings at the configured dimensions" do
    vector = Array.new(Chunk.embedding_dimensions, 0.05)
    chunk = Chunk.new(account: @account, chunkable: @website, content: nil)
    chunk.embedding = vector

    assert_nothing_raised { chunk.save! }
  end

  test "the embedding column matches the configured dimensions" do
    sql_type = ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT format_type(atttypid, atttypmod) FROM pg_attribute
      WHERE attrelid = 'chunks'::regclass AND attname = 'embedding'
    SQL

    assert_equal "vector(#{Chunk.embedding_dimensions})", sql_type
  end

  test "the embedding column is indexed when dimensions allow" do
    index = ActiveRecord::Base.connection.indexes(:chunks).find do |candidate|
      candidate.columns == [ "embedding" ]
    end

    if Chunk.embedding_dimensions <= 2000
      assert index, "expected an hnsw index on chunks.embedding"
    else
      assert_nil index, "vector indexes cap at 2000 dims; wider configs must not pretend to have one"
    end
  end

  test "nearest_neighbors runs against the stored embeddings" do
    chunk = Chunk.create!(account: @account, chunkable: @website)
    chunk.update_columns(embedding: Array.new(Chunk.embedding_dimensions, 0.1))

    results = @account.chunks.nearest_neighbors(:embedding, Array.new(Chunk.embedding_dimensions, 0.1), distance: :cosine)

    assert_includes results.map(&:id), chunk.id
  end
end
