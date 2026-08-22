require "test_helper"
require "turbo/broadcastable/test_helper"

class ChatStopGenerationTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActionView::RecordIdentifier

  def setup
    @user = User.create!(email: "csg@example.com", password: "testpassword123")
    @account = Account.create!(name: "CSG Account", owner: @user)
    ActsAsTenant.current_tenant = @account
    @chat = @account.chats.create!(user: @user, model: "test-model", provider: :openai, assume_model_exists: true)
    # Neutralize the ruby_llm surface except the streaming block under test.
    stub_chat_for_streaming(@chat, chunks: [])
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  def stub_complete(chunks:)
    chat_ref = @chat
    streamed = []
    @chat.define_singleton_method(:complete) do |&block|
      placeholder = messages.create!(role: :assistant, content: "")
      chunks.each do |chunk|
        block.call(chunk)
        streamed << chunk.content
      end
      placeholder.reload
    end
    streamed
  end

  # A stop aborts before ruby_llm persists the final message, so the partial
  # answer must be written into the placeholder from the stream buffer or it
  # vanishes on reload.
  test "stop_generation! halts the stream and keeps the partial answer" do
    @chat.start_generation!
    assert_not @chat.generation_stopped?

    chunks = [ StreamChunk.new("Hel"), StreamChunk.new("lo "), StreamChunk.new("world") ]
    chat_ref = @chat
    streamed = []
    @chat.define_singleton_method(:complete) do |&block|
      placeholder = messages.create!(role: :assistant, content: "")
      chunks.each do |chunk|
        block.call(chunk)
        streamed << chunk.content
        # Simulate the user hitting stop between the second and third chunk.
        chat_ref.update_column(:stopped_at, Time.current) if streamed.size == 2
      end
      placeholder.reload
    end

    message = @chat.complete_with_nosia("hi")

    assert_equal [ "Hel", "lo " ], streamed, "the loop must not consume chunks after the stop flag is set"
    assert_predicate message, :assistant?
    # The third chunk never arrived; everything received before the stop is kept.
    assert_equal "Hello ", message.reload.content
  end

  test "starting a new generation clears a stale stop flag" do
    @chat.update_column(:stopped_at, Time.current)

    @chat.start_generation!

    assert_not @chat.generation_stopped?
  end

  test "a stop before any chunk leaves no partial content" do
    @chat.start_generation!
    # The user clicks stop in the window before the first chunk arrives.
    @chat.stop_generation!
    stub_complete(chunks: [ StreamChunk.new("ignored") ])

    message = @chat.complete_with_nosia("hi")

    assert_nil message
    assert_equal "", @chat.messages.assistant.last.reload.content
  end
end
