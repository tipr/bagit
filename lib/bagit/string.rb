# Some mixed in functionality for String
class String
  
  # Wrap a string to lines of a specified width. All existing newlines
  # are not guaranteed to be preserved
  def wrap(width)
    s = gsub(/\s+/, ' ').strip

    if s.length > width
      s[0...width] + '\n' + s[width..-1].wrap(width)
    else
      s
    end

  end
  
  # Indent each line of a string by n spaces
  def indent(n)
    indent = ' ' * n
    gsub '\n', "\n#{indent}"
  end

end
