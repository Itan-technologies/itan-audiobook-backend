class AudioChunkJob < ApplicationJob
  queue_as :audio_processing
  
  def perform(book_id, chunk, index, total_chunks)
    book = Book.find(book_id)
    
    begin
      # Convert chunk to audio
      eleven_labs = ElevenLabsApi.new
      audio_data = eleven_labs.text_to_speech(chunk)
      
      # Store chunk
      book.audio_chunks.attach(
        io: StringIO.new(audio_data),
        filename: "chunk_#{index.to_s.rjust(5, '0')}.mp3",
        content_type: "audio/mpeg"
      )
      
      # Update progress
      book.with_lock do
        book.processed_chunks = (book.processed_chunks || 0) + 1
        book.audio_progress = (book.processed_chunks.to_f / total_chunks * 100).round
        
        # If we've processed all chunks, queue the finalization
        if book.processed_chunks >= total_chunks
          AudioFinalizationJob.perform_later(book_id)
        end
        
        book.save!
      end
      
    rescue => e
      book.update(audio_status: "chunk_failed", 
                 audio_error: "Error on chunk #{index+1}: #{e.message}")
    end
  end
end