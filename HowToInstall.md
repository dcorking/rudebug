# On Windows #
  1. Get ruby-gtk2 to work. See http://ruby-gnome2.sourceforge.jp/hiki.cgi?Install+Guide+for+Windows (This shouldn't be too much work and you only need to do it once.)
  1. Install rudebug by typing `gem install rudebug` into a console. This will automatically install all dependencies as well. (If you get asked to "Select which gem to install for your platform" for any gem select "mswin32")

# On Linux #
  1. Install ruby-gtk2 as well as libglade2 (in ruby-gnome2)
  1. (As root) install rudebug: `gem install rudebug` (select the latest linux gem if you are prompted with a list of gems)

# On Mac OS X #

I'm not even able to get an X11 build of GTK2 to work on my MacBook using either DarwinPorts or Fink. Sorry.
I might port this to ruby-cocoa in the future.