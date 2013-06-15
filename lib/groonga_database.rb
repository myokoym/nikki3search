require "groonga"

class GroongaDatabase
  def initialize
    @database = nil
  end

  def open(base_path, encoding=:utf8)
    reset_context(encoding)
    path = File.join(base_path, "nikki-search.db")
    if File.exist?(path)
      @database = Groonga::Database.open(path)
      populate_schema
    else
      FileUtils.mkdir_p(base_path)
      populate(path)
    end
    if block_given?
      begin
        yield(self)
      ensure
        close unless closed?
      end
    end
  end

  def add(url, html)
    pages = Groonga["Pages"]
    pages.add(url, :html => html)
  end

  def close
    @database.close
    @database = nil
  end

  def closed?
    @database.nil? or @database.closed?
  end

  def pages
    @pages ||= Groonga["Pages"]
  end

  private
  def reset_context(encoding)
    Groonga::Context.default_options = {:encoding => encoding}
    Groonga::Context.default = nil
  end

  def populate(path)
    @database = Groonga::Database.create(:path => path)
    populate_schema
  end

  def populate_schema
    Groonga::Schema.define do |schema|
      schema.create_table("Pages", :type => :hash) do |table|
        table.text("html")
      end

      schema.create_table("Terms",
                          :type => :patricia_trie,
                          :key_normalize => true,
                          :default_tokenizer => "TokenBigram") do |table|
        table.index("Pages.html")
      end
    end
  end
end
