require "../spec_helper"

Colorize.enabled = true

describe Jennifer::Adapter::DBColorizedFormatter do
  described_class = Jennifer::Adapter::DBColorizedFormatter

  describe "#run" do
    it "formats an entry" do
      metadata = {query: "SELECT COUNT(*) FROM users WHERE id > ?", args: "[1]", time: 582.1}
      entry = Log::Entry.new("db", :info, "ignored message", Log::Metadata.build(metadata), nil)
      io = IO::Memory.new
      described_class.format(entry, io)
      io.to_s
        .should match(/^[\d\-\.:TZ]+\s* INFO - \e\[31mdb\e\[0m: #{Regex.escape(metadata[:time].to_s)} μs \e\[34m#{Regex.escape(metadata[:query])}\e\[0m \| \e\[33m#{Regex.escape(metadata[:args])}\e\[0m$/)
    end
  end
end
