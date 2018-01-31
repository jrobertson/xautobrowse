# Introducing the xautobrowse gem

## Installation

* `apt-get install xclip libx11-dev libglib2.0-dev libxmu-dev`
* `gem install xautobrowse`

## Example 

    require 'xautobrowse'

    browser = XAutoBrowse.new 'firefox'
    browser.window.move 0,0
    browser.goto "http://www.jamesrobertson.eu"

    # search snippets using keyword 'dynarex'

    browser.go do |x|
      x.text_field id: 'keyword', value: 's: dynarex' 
    end

The above example would launch Firefox, navigate to http://www.jamesrobertson.eu, and search the code snippets using the keyword *dynarex*. Observed the search results page containing links to code snippets related to Dynarex.

Note: This gem depends on tools which are solely written for the X Windows system.

## Resources

* xautobrowse https://rubygems.org/gems/xautobrowse

xautobrowse automation
