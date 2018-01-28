#!/usr/bin/env ruby

# file: xautobrowse.rb

# description: Runs on an X Windows system (e.g. Debian running LXDE)
#              Primarily tested using Firefox (52.6.0 (64-bit)) on Debian.


# modifications

# 28 Jan 2018: feature: Chromium is now supported. 
#                     A custom accesskey can now be used to jump to an element.


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
    spawn(browser.to_s); sleep 5
    
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
  
  # custom accesskey (e.g. CTRL+SHIFT+S) typically used to reference an 
  # element on the web page
  #
  def accesskey(key)
    XDo::Keyboard.send key.to_sym
  end
  
  alias access_key accesskey

  def activate()
    @wm.action_window(@id, :activate)
  end
  
  def copy_source()
    
    view_source(); sleep 3
    ctrl_a() # select all
    sleep 1
    ctrl_c() # copy the source code to the clipboard
    
  end
  
  # select all
  #
  def ctrl_a() XDo::Keyboard.ctrl_a  end
  
  # copy
  #
  def ctrl_c() XDo::Keyboard.ctrl_c  end
  
  # jump to the location bar
  #
  def ctrl_l() XDo::Keyboard.ctrl_l  end  
  
  # view source code
  #
  def ctrl_u() XDo::Keyboard.ctrl_u  end  

  # developer tools
  #
  def ctrl_shift_i() XDo::Keyboard.ctrl_shift_i end    
  
  # submit a form by pressing return
  #
  def go()
    
    if block_given? then
      
      activate(); sleep 2    
      yield(self)     
      carriage_return()
      
    end
    
  end
  
  def goto(url)
    
    activate(); sleep 0.5
    ctrl_l();   sleep 0.5
    enter(url); sleep 4

  end  

  def move(x,y)
    @x, @y = x, y
    @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
  end

  def resize(width, height)
    @width, @height = width, height
    @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
  end
  
  def carriage_return()
    XDo::Keyboard.return
  end
  
  alias cr carriage_return
  
  def tab(n=1)
    XDo::Keyboard.simulate("{TAB}" * n)
  end
  
  def text_field(klass: nil, id: nil, name: nil, value: '')
    
    console  = @browser == :firefox ? :ctrl_shift_k : :ctrl_shift_i
    method(console).call # web console
    
    sleep 3
    
    cmd = if klass then
      "r = document.querySelector('#{klass}')"
    elsif id then
      "r = document.getElementById(\"#{id}\")"
    end

    [cmd, "r.value = \"\"", "r.focus()"].each {|x| enter x}
    
    ctrl_shift_i()  # toggle tools
    sleep 2
    type(value); sleep 1

  end
  
  def to_doc()
    copy_source(); sleep 0.5
    Nokorexi.new(Clipboard.paste).to_doc
  end
  
  def type(s)
    XDo::Keyboard.type(s)
  end
  
  def view_source()
    
    activate(); sleep 0.5
    ctrl_l() # jump to the location bar
    sleep 0.6
    tab(2); sleep 0.5
    ctrl_u()  # View source code
    
  end  
  
  # input some text
  #
  def enter(s) type(s); sleep 0.8; carriage_return(); sleep 1  end

end
