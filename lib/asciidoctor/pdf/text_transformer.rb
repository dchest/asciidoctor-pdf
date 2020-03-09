# frozen_string_literal: true

unless RUBY_VERSION >= '2.4'
  begin
    require 'unicode' unless defined? Unicode::VERSION
  rescue LoadError
    begin
      require 'active_support/multibyte' unless defined? ActiveSupport::Multibyte
    rescue LoadError; end
  end
end

module Asciidoctor
  module PDF
    module TextTransformer
      XMLMarkupRx = /&#?[a-z\d]+;|</
      PCDATAFilterRx = /(&#?[a-z\d]+;|<[^>]+>)|([^&<]+)/
      TagFilterRx = /(<[^>]+>)|([^<]+)/
      WordRx = /\S+/
      CodePunctuationRx = /[\/\\.,_]/
      Hyphen = '-'
      SoftHyphen = ?\u00ad
      HyphenatedHyphen = '-' + SoftHyphen
      Ligatures = {
        # "ffi" => "ﬃ",
        # "ffl" => "ﬄ",
        "fi"  => "ﬁ",
        "fl"  => "ﬂ",
        # "ff"  => "ﬀ",
      }

      def ligaturize_pcdata string
        if XMLMarkupRx.match? string
          tag = ""
          string.gsub(PCDATAFilterRx) { $2 ? (ligaturize_words_mb $2, tag) : ($1[0] == '<' ? (tag = $1) : $1) }
        else
          ligaturize_words_mb string, ""
        end
      end

      def ligaturize_words_mb string, tag
        return string if tag == '<code>'
        Ligatures.each { |s, rep| string = string.gsub s, rep }
        string
      end

      def capitalize_words_pcdata string
        if XMLMarkupRx.match? string
          string.gsub(PCDATAFilterRx) { $2 ? (capitalize_words_mb $2) : $1 }
        else
          capitalize_words_mb string
        end
      end

      def capitalize_words_mb string
        string.gsub(WordRx) { capitalize_mb $& }
      end

      def hyphenate_words_pcdata string, hyphenator
        if XMLMarkupRx.match? string
          tag = ""
          string.gsub(PCDATAFilterRx) { $2 ? (hyphenate_words $2, tag, hyphenator) : ($1[0] == '<' ? (tag = $1) : $1) }
        else
          hyphenate_words string, "", hyphenator
        end
      end

      def hyphenate_words string, tag, hyphenator
        if tag == '<code>' or tag.start_with? "<a href"
          string.gsub(CodePunctuationRx) { "#{$&}\u200B" }
        else
          string.gsub(WordRx) { (hyphenator.visualize $&, SoftHyphen).gsub HyphenatedHyphen, Hyphen }
        end
      end

      def lowercase_pcdata string
        if string.include? '<'
          string.gsub(TagFilterRx) { $2 ? (lowercase_mb $2) : $1 }
        else
          lowercase_mb string
        end
      end

      def uppercase_pcdata string
        if XMLMarkupRx.match? string
          string.gsub(PCDATAFilterRx) { $2 ? (uppercase_mb $2) : $1 }
        else
          uppercase_mb string
        end
      end

      if RUBY_VERSION >= '2.4'
        def capitalize_mb string
          string.capitalize
        end

        def lowercase_mb string
          string.downcase
        end

        def uppercase_mb string
          string.upcase
        end
      # NOTE Unicode library is 4x as fast as ActiveSupport::MultiByte::Chars
      elsif defined? ::Unicode
        def capitalize_mb string
          string.ascii_only? ? string.capitalize : (::Unicode.capitalize string)
        end

        def lowercase_mb string
          string.ascii_only? ? string.downcase : (::Unicode.downcase string)
        end

        def uppercase_mb string
          string.ascii_only? ? string.upcase : (::Unicode.upcase string)
        end
      elsif defined? ::ActiveSupport::Multibyte
        MultibyteChars = ::ActiveSupport::Multibyte::Chars

        def capitalize_mb string
          string.ascii_only? ? string.capitalize : (MultibyteChars.new string).capitalize.to_s
        end

        def lowercase_mb string
          string.ascii_only? ? string.downcase : (MultibyteChars.new string).downcase.to_s
        end

        def uppercase_mb string
          string.ascii_only? ? string.upcase : (MultibyteChars.new string).upcase.to_s
        end
      else
        def capitalize_mb string
          string.capitalize
        end

        def lowercase_mb string
          string.downcase
        end

        def uppercase_mb string
          string.upcase
        end
      end
    end
  end
end
