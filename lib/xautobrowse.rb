#!/usr/bin/env ruby

# file: xautobrowse.rb

# description: Runs on an X Windows system (e.g. Debian running LXDE)
#              Primarily tested using Firefox (52.6.0 (64-bit)) on Debian.



# revision log:

# 23 Jun 2018: feature: A new Window can now be created which attaches itself 
#                       to the most recent application window created
# 12 Feb 2018: bug fix: Implemented the missing method ctrl_shift_k() used 
#      to access developer tools from Firefox. The browser variable is now a 
#      symbolic string instead of a regular string as required by the code.
#  1 Feb 2018: feature: Implemented XAutoBrowse#screenshot
# 31 Jan 2018: feature: Implemented XAutoBrowse#click which accepts a key of 
#                       an element to be clicked e.g. click :logout
# 30 Jan 2018: feature: Now uses the gem universal_dom_remote to 
#                       connect to the browser via websockets. 
#                       A window can now be closed remotely.
#                       SPS is now optional given there is no secure 
#                       websockets support
# 28 Jan 2018: feature: Chromium is now supported. 
#                     A custom accesskey can now be used to jump to an element.

# Helpful tip: To identify the id for a web page element, using the mouse 
#      right-click on the element, select inspect. Then from the inspection 
#      window, hover the mouse over the element code, using the mouse, 
#      right-click, select copy, inner HTML. 
#      Then paste the code to a new notepad document for inspection.


require 'wmctrl'
require 'nokorexi'
require 'clipboard'
require 'xdo/mouse'
require 'xdo/keyboard'
require 'xdo/xwindow'
require 'sps-pub'
require 'universal_dom_remote'



class XAutoBrowse
  
  at_exit() do
    
    if @sps then
      puts 'shutting down ...'
      EventMachine.stop
      SPSPub.notice('shutdown', host: '127.0.0.1', port: '55000'); sleep 0.5
    end
    
  end
  
  class Window
    
    def initialize(browser=nil)
            
      @wm = WMCtrl.instance
      
      if browser then
        spawn(browser.to_s); sleep 3
        
        id = XDo::XWindow.wait_for_window(browser.to_s)

        xwin = XDo::XWindow.new(id)
        title = xwin.title
        puts 'title:  ' + title.inspect if @debug

        # WMCtrl is used because XDo is problematic at trying to activate a window
        
        a = @wm.list_windows true
        puts 'a: '  + a.inspect if @debug
        r = a.reverse.find {|x| x[:title] =~ /#{browser}$/i}
      else
        a = @wm.list_windows true
        r = a.last
      end      
      
      @id = r[:id]

      @x, @y, @width, @height = *r[:geometry]      
      sleep 4 unless browser
      
    end
    
    def activate()
      @wm.action_window(@id, :activate)
    end
    
    def height=(val)
      @height = val
      @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
    end            
    
    def move(x,y)
      @x, @y = x, y
      @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
    end    
    
    def resize_to(width, height)
      @width, @height = width, height
      @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
    end
    
    alias resize resize_to

    def width=(val)
      @width = val
      @wm.action_window(@id, :move_resize, 0, @x, @y, @width, @height)
    end        
  end
  
  attr_reader :window
  attr_accessor :actions
  
  
  def initialize(browser= :firefox, debug: false, sps: false, clicks: {})

    @browser, @debug, @sps, @clicks = browser.to_sym, debug, sps, clicks
    
    @window = Window.new(browser); sleep 2
    #Thread.new { web_console() { sleep 1 } }
    sleep 2
    
    connect() if sps
    
  end
  
  # custom accesskey (e.g. CTRL+SHIFT+S) typically used to reference an 
  # element on the web page
  #
  def accesskey(key) send_keys(key.to_sym)  end
  
  alias access_key accesskey  
  
  # Attaches the SPS client to the web browser. The SPS broker must be 
  # started before the code can be attached. see start_broker()
  #
  def attach_console(autohide: true)
    
    @window.activate()
    open_web_console(); sleep 1

    clipboard = Clipboard.paste    
    Clipboard.copy javascript(); sleep 1
    ctrl_v(); sleep 0.5; carriage_return()
    
    close_web_console() if autohide
    Clipboard.copy clipboard
    
  end
  
  def click(name)
    
    web_console {|x| x.enter @clicks[name] + '.click();' }
    
  end  
  
  def close()
    ctrl_w()
  end
  
  alias exit close
  
  def close_web_console()
    @window.activate()
    ctrl_shift_i()
  end
  
  alias hide_web_console close_web_console
  
  def connect()

    start_broker(); sleep 4; connect_controller()
    
  end
  
  # Connects to the SPS broker to communicate with the web browser
  #
  def connect_controller()
    
    @udr = UniversalDomRemote.new debug: @debug
    
  end
  
  def copy_screen()
    select_all(); sleep 2; ctrl_c(); sleep 2; unselect_all()
    Clipboard.paste    
  end
  
  alias scrape_screen copy_screen
  
  def copy_source()
    
    view_source(); sleep 3
    select_all(); sleep 1
    ctrl_c() # copy the source code to the clipboard
    sleep 1
    ctrl_w() # close the viewsource window
    
  end
  
  # select all
  #
  def ctrl_a() send_keys(:ctrl_a)  end
    
  # unselect all
  #
  def ctrl_shift_a()

    XDo::Keyboard.key_down('shift')
    send_keys(:ctrl_a)
    XDo::Keyboard.key_up('shift')    

  end    
  
  # copy
  #
  def ctrl_c() send_keys(:ctrl_c)  end
  
  # jump to the location bar
  #
  def ctrl_l() send_keys(:ctrl_l)  end  
  
  # view source code
  #
  def ctrl_u() send_keys(:ctrl_u)  end  
    
  # paste
  #
  def ctrl_v() send_keys(:ctrl_v)  end
    
  # close the current window
  #
  def ctrl_w() send_keys(:ctrl_w)  end    

  # Chromium developer tools
  #
  def ctrl_shift_i() send_keys(:ctrl_shift_i) end

  # Firefox developer tools
  #
  def ctrl_shift_k() send_keys(:ctrl_shift_k) end
      
  # submit a form by pressing return
  #
  def go()
    
    if block_given? then
      
      @window.activate(); sleep 1; yield(self); carriage_return()
      
    end
    
  end
  
  def goto(url, attachconsole: true)
    
    sleep 1; ctrl_l(); sleep 2
    enter(url); sleep 5
    attach_console() if @sps and attachconsole

  end  
  
  def carriage_return()
    @window.activate(); sleep 1; XDo::Keyboard.return
  end
  
  alias cr carriage_return
  
  def open_web_console()
    
    console  = @browser == :firefox ? :ctrl_shift_k : :ctrl_shift_i
    method(console).call # web console
    
    sleep 2
    
    if block_given? then
      yield(self)
      close_web_console()
    end
    
  end
  
  alias web_console open_web_console
  
  def new_window()
    @window = Window.new
  end
  
  # Takes a screenshot of the web page. Images are stored in ~/Pictures
  #
  def screenshot(filename=Time.now\
                 .strftime("Screenshot from %Y-%m-%d %d-%m-%y"))
    
    XDo::Keyboard.simulate('{print}'); 
    sleep 4; 
    XDo::Keyboard.simulate("{down}")
    sleep 4; 
    XDo::Keyboard.alt_s    
    sleep 5;
    XDo::Keyboard.type filename
    sleep 3
    XDo::Keyboard.alt_s
    sleep 1
    
  end
  
  alias screen_capture screenshot
  
  def send(s)
    @udr.send s
  end
    
  def select_all()
    ctrl_a()
  end
  
  def unselect_all()
    
    @browser == :firefox ? (tab(); shift_tab()) : ctrl_shift_a()
    
  end
  
  # Starts the simplepubsub broker
  
  def start_broker()
    
    Thread.new do 
      `ruby -r 'simplepubsub' -e "SimplePubSub::Broker.start port: '55000'"`
    end
    
  end
  
  def stop_broker()
    SPSPub.notice 'shutdown', host: '127.0.0.1', port: '55000'
  end
  
  def shift_tab(n=1)
    
    @window.activate()
    XDo::Keyboard.key_down('shift')
    XDo::Keyboard.simulate("{TAB}" * n)
    XDo::Keyboard.key_up('shift')
    
  end
  
  def tab(n=1)
    @window.activate(); XDo::Keyboard.simulate("{TAB}" * n)
  end
  
  def text_field(klass: nil, id: nil, name: nil, value: '')
    
    open_web_console() do |console|
    
      cmd = if klass then
        "querySelector('#{klass}')"
      elsif id then
        "getElementById(\"#{id}\")"
      end

      ['r = document.' + cmd, "r.value = \"\"", "r.focus()"].each do |x|
        console.enter x
      end
    
    end
    
    sleep 2; type(value); sleep 1

  end
  
  def to_doc()
    copy_source(); sleep 0.5
    Nokorexi.new(Clipboard.paste).to_doc
  end
  
  # type some text
  #
  def type(s)  @window.activate(); XDo::Keyboard.type(s)  end
  
  def view_source()
    
    @window.activate(); sleep 0.5
    ctrl_l() # jump to the location bar
    sleep 0.6; tab(2); sleep 0.5; ctrl_u()  # View source code
    
  end  
  
  
  # input some text
  #
  def enter(s=nil)
    
    if s then
      type(s)
      sleep 0.8
    end
    
    carriage_return()
    sleep 1
    
  end

    
  private
  
  # A helpful method to generate the javascript code necessary for the
  # web browser to communicate with the universal DOM remote
  #
  def javascript()

"
var ws = new WebSocket('ws://127.0.0.1:55000/');
ws.onopen = function() {
  console.log('CONNECT');
  ws.send('subscribe to topic: udr/controller');
};
ws.onclose = function() {
  console.log('DISCONNECT');
};
ws.onmessage = function(event) {

  var a = event.data.split(/: +/,2);
  console.log(a[1]);

  try {
    r = eval(a[1]);
  }
  catch(err) {
    r = err.message;
  }

  ws.send('udr/browser: ' + r);

};
"

  end  
  
  def send_keys(keys)
    
    @window.activate(); XDo::Keyboard.send keys.to_sym    
    
  end
end
