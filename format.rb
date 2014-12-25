#!/usr/bin/env ruby

if !File.exists? ARGV[0]
  puts "Please provide a valid file"
  exit 1
end

$xml = File.open(ARGV[0], 'r').read

$indent_level = 0
length = $xml.length
$cursor = 0
$debug = false

$outfile = File.open('out.xml', 'w')

def indent
  "    " * $indent_level
end

def linebreak
  write "\n" + indent
end

def debug(str)
  write(str) if $debug
end

def write(str)
  #puts str
  $outfile.write str
end

def write_until(str)
  while $xml[$cursor, str.length] != str
    write $xml[$cursor]
    $cursor += 1
  end
end

def write_until_including(str)
  write_until(str)
  write $xml[$cursor, str.length]
  $cursor += str.length
end

def change_indent(amount)
  if amount > 0
    debug "+#{amount}"
  else
    debug amount
  end

  $indent_level += amount
end





# begin: look-ahead / behind methods

def last_element_is_tag?
  i = 1
  while $xml[$cursor - i] == ' ' || $xml[$cursor - i] == "\n"
    i += 1
  end

  tag = $xml[$cursor - i] == '>'
  if tag
    debug "!!!tag!!!"
  end

  tag
end

def this_element_is_shorttag?
  i = 1
  while $xml[$cursor + i] != '>'
    i += 1
  end


  short = $xml[$cursor + i - 1] == '/'
  if short
    debug "!!!short!!!"
  end

  short
end

# end: look-ahead / behind methods



while $cursor < length

  if $xml[$cursor, 2] == "\r\n"
    puts "This tool doesn't work with Windows linebreaks"
    exit 1
  end

  if $xml[$cursor] == "\t"
    puts "This tool can't handle tabs"
    exit 2
  end



  # Format newlines
  if $xml[$cursor] == "\n"
    $cursor += 1
    while $xml[$cursor] == " "
      $cursor += 1
    end

    if $xml[$cursor, 2] =~ /<[a-zA-Z]{1}/
      # do nothing
    else
      linebreak
    end



  # match $xml comments
  elsif $xml[$cursor, 4] == "<!--"
    while $xml[$cursor, 3] != "-->"
      write $xml[$cursor]
      $cursor += 1
    end

    write $xml[$cursor, 3]
    $cursor += 3

    linebreak



  # treat figures separately, because we should not touch
  # anything that happens inside them.
  elsif $xml[$cursor, 7] == "<figure"
    write_until_including "</figure>"



  # match opening $xml tags
  elsif $xml[$cursor, 2] =~ /<[a-zA-Z]{1}/ && !this_element_is_shorttag?
    #if last_element_is_tag?
      linebreak
    #end

    change_indent(+1)
    write $xml[$cursor, 2]
    $cursor += 2

    # while $xml[$cursor] != '>'
    #   write $xml[$cursor]
    #   $cursor += 1
    # end

    write_until '>'

    write $xml[$cursor]
    linebreak
    $cursor += 1



  # match closing $xml tags
  elsif $xml[$cursor, 2] =~ /(<\/)/
    change_indent(-1)
    linebreak

    write $xml[$cursor, 2]
    $cursor += 2


  # match everything else
  else
    write $xml[$cursor]
    $cursor += 1
  end
end #while