# app/jobs/book_processing_job.rb
class BookProcessingJob < ApplicationJob
  queue_as :default
  
  def perform(book_id)
    book = Book.find(book_id)
    
    begin
      # Extract text
      text = TextExtractorService.extract(book)
      chunks = split_text(text, 3800)
      
      # Setup for processing
      book.update(
        audio_status: "processing",
        total_chunks: chunks.size, 
        processed_chunks: 0,
        audio_progress: 0
      )
      
      # Queue individual chunks
      chunks.each_with_index do |chunk, index|
        AudioChunkJob.perform_later(book_id, chunk, index, chunks.size)
      end
      
    rescue => e
      book.update(audio_status: "failed", audio_error: e.message)
    end
  end
  
  private
  
  def split_text(text, max_length)
    # Split text on sentence boundaries
    sentences = text.gsub(/\s+/, ' ').split(/(?<=[.!?])\s+/)
    
    chunks = []
    current_chunk = ""
    
    sentences.each do |sentence|
      # Check if adding this sentence would exceed the limit
      if (current_chunk.length + sentence.length) < max_length
        current_chunk << sentence + " "
      else
        # If current chunk has content, add it to chunks
        chunks << current_chunk.strip unless current_chunk.empty?
        
        # Handle sentences that are longer than max_length
        if sentence.length > max_length
          # Split long sentence at word boundaries
          words = sentence.split(/\s+/)
          partial_sentence = ""
          
          words.each do |word|
            if (partial_sentence.length + word.length + 1) < max_length
              partial_sentence << word + " "
            else
              chunks << partial_sentence.strip unless partial_sentence.empty?
              partial_sentence = word + " "
            end
          end
          
          # Add any remaining partial sentence
          current_chunk = partial_sentence
        else
          # Start a new chunk with this sentence
          current_chunk = sentence + " "
        end
      end
    end
    
    # Add the final chunk if it has content
    chunks << current_chunk.strip unless current_chunk.empty?
    chunks
  end
end