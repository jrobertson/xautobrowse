#!/usr/bin/env ruby

# file: xautobrowse.rb

# description: Runs on an X Windows system (e.g. Debian running LXDE)
#              Primarily tested using Firefox (52.6.0 (64-bit)) on Debian.


# modifications

# 28 Jan 2018: feature: Chromium is now supported


require 'wmctrl'
require 'nokorexi'
require 'clipboard'
require "xdo/mouse"
require "xdo/keyboard"
require "xdo/xwindow"



class XAutoBrowse

  def initialize(browser= :firefox, debug: false)

    @browser, @debug = browser, debug
    
    @wm = WMCtrl.instance
    spawn(browser.to_s)
    sleep 5
    
    id = XDo::XWindow.wait_for_window(browser)
    xwin = XDo::XWindow.new(id)
    title = xwin.title
    puts 'title:  ' + title.inspect if @debug

    # WMCtrl is used because XDo is problematic at trying to activate a window
    
    a = @wm.list_windows true
    puts 'a: '  + a.inspect if @debug
    r = a.reverse.find {|x| x[:title] =~ /#{browser}$/i}
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
    enter(url)
    sleep 4

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
    
    console  = @browser == :firefox ? :ctrl_shift_k : :ctrl_shift_i
    XDo::Keyboard.send console # web console
    
    sleep 3
    
    cmd = if klass then
      "r = document.querySelector('#{klass}')"
    elsif id then
      "r = document.getElementById(\"#{id}\")"
    end

    [cmd, "r.value = \"\"", "r.focus()"].each {|x| enter x}
    
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
  
  private
  
  def enter(s)
    XDo::Keyboard.type(s)
    sleep 0.8
    XDo::Keyboard.return    
    sleep 1  
  end

end
