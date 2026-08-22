class StoreApiTokenDigests < ActiveRecord::Migration[8.0]
  def up
    add_column :api_tokens, :token_digest, :string

    # Backfill digests from the existing plaintext before dropping it.
    # sha256() ships with PostgreSQL 11+.
    execute <<~SQL
      UPDATE api_tokens SET token_digest = encode(sha256(token::bytea), 'hex')
    SQL

    change_column_null :api_tokens, :token_digest, true
    add_index :api_tokens, :token_digest, unique: true
    remove_column :api_tokens, :token
  end

  def down
    add_column :api_tokens, :token, :string
    remove_index :api_tokens, :token_digest
    remove_column :api_tokens, :token_digest
  end
end
