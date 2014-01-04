module PBManager

  # The base class for all module errors.
  class Error < RuntimeError
    attr_reader :original

    def initialize(message, original=nil)
      super(message)
      @original = original
     end

    def process

      puts "==========================   PBManager::Error Processing  ==========================="
      unless original.nil?
        puts "Original: #{original.class} => #{original.message}"
        PBManager::log.fatal(original.message)
      end
      puts "#{self.class} => #{self.message}  (See log for details)"
      #puts "Backtrace:\n\t#{self.backtrace.join("\n\t")}"
      PBManager::log.fatal("#{self.class} => #{self.message}")
      PBManager::log.fatal("Backtrace:\n\t#{self.backtrace.join("\n\t")}")
    end

  end

  class RecoverableError < Error

  end

  class FatalError < Error

  end

end