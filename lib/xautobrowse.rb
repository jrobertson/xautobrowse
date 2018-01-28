#!/usr/bin/env ruby

# file: xautobrowse.rb

# description: Runs on an X Windows system (e.g. Debian running LXDE)
#              Primarily tested using Firefox (52.6.0 (64-bit)) on Debian.

require 'wmctrl'
require 'nokorexi'
require 'clipboard'
require "xdo/mouse"
require "xdo/keyboard"
require "xdo/xwindow"



class XAutoBrowse

  def initialize(browser_name, debug: false)

    @debug = debug
    
    @wm = WMCtrl.instance
    spawn(browser_name)
    sleep 4
    id = XDo::XWindow.wait_for_window(browser_name)
    xwin = XDo::XWindow.new(id)
    title = xwin.title
    puts 'title:  ' + title.inspect if @debug

    # WMCtrl is used because XDo is problematic at trying to activate a window
    
    a = @wm.list_windows true
    puts 'a: '  + a.inspect if @debug
    r = a.find {|x| x[:title] =~ /#{browser_name}$/i}
    @id = r[:id]

    @x, @y, @width, @height = *r[:geometry]

  end

  def activate()
    @wm.action_window(@id, :activate)
  end
  
  def copy_source()
    
    view_source()
    sleep 3
    XDo::Keyboard.ctrl_a # select all
    sleep 1
    XDo::Keyboard.ctrl_c # copy the source code to the clipboard
    
  end
  
  def go()
    
    activate()
    sleep 2
    if block_given? then
      yield(self)
    end
    
    XDo::Keyboard.return        
    
  end
  
  def goto(url)
    
    @wm.action_window(@id, :activate)
    sleep 0.5
    XDo::Keyboard.ctrl_l
    sleep 0.5
    XDo::Keyboard.type(url)
    XDo::Keyboard.return
    sleep 5

  end  

  def move(x,y)
    @x, @y = x, y
    @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
  end

  def resize(width, height)
    @width, @height = width, height
    @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
  end
  
  def text_field(klass: nil, id: nil, name: nil, value: '')
    
    XDo::Keyboard.ctrl_shift_k # web console
    sleep 5
    
    if klass then
      XDo::Keyboard.type("r = document.querySelector('#{klass}')")
    elsif id then
      XDo::Keyboard.type("r = document.getElementById(\"#{id}\")")
    end
    sleep 3
    XDo::Keyboard.return              
    sleep 2
    XDo::Keyboard.type("r.value = \"\"")
    sleep 2
    XDo::Keyboard.return    
    sleep 1
    XDo::Keyboard.type("r.focus()")
    sleep 2
    XDo::Keyboard.return
    sleep 2
    XDo::Keyboard.ctrl_shift_i  # toggle tools
    sleep 2
    XDo::Keyboard.type(value)
    sleep 2

  end
  
  def to_doc()
    copy_source()
    sleep 0.5
    Nokorexi.new(Clipboard.paste).to_doc
  end
  
  def view_source()
    
    @wm.action_window(@id, :activate)
    sleep 0.5
    XDo::Keyboard.ctrl_l # jump to the location bar
    sleep 0.6
    XDo::Keyboard.simulate("{TAB}" * 2)
    sleep 0.5
    XDo::Keyboard.ctrl_u  # View source code
  end

end

