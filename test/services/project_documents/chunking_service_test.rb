require "test_helper"

module ProjectDocuments
  class ChunkingServiceTest < ActiveSupport::TestCase
    test "un texte court tient dans un seul chunk" do
      assert_equal ["Un texte court."], ChunkingService.call("Un texte court.")
    end

    test "un texte vide ne produit aucun chunk" do
      assert_equal [], ChunkingService.call("")
      assert_equal [], ChunkingService.call(nil)
    end

    test "un texte long est découpé en plusieurs chunks, sans trou jusqu'à la fin du texte" do
      text = (1..400).map { |i| "phrase numéro #{i}. " }.join
      chunks = ChunkingService.call(text)

      assert chunks.length > 1
      assert chunks.all? { |c| c.length <= ChunkingService::CHUNK_SIZE }
      assert text.strip.start_with?(chunks.first)
      assert text.strip.end_with?(chunks.last)
    end
  end
end
