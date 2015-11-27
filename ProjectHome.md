rudebug is written using Ruby-GNOME2 and Glade. It has support for local and remote debugging with ruby-debug and ruby-breakpoint. It should work fine on Windows and Linux.

It has stepping support, a source code display, a powerful object browser and an interactive shell as well as additional integration and polish to make those components work together well.

It is in an early stage and will likely remain so until I have a way of using it on Mac OS X. I don't want this to molder on my hard disk however without ever having seen a public release.

With ~900 lines of actual code (excluding the glade file) it is fairly light-weight. Code quality fluctuates. Some of the code needs to be unusual because it is executed on the server and can't touch its environment, other bits could probably need some refactoring.

It was developed as part of a Summer of Code 2006 project for RubyCentral Inc.

Dependencies: Ruby-GNOME2, _rsyntax_, _ruby-debug_ (_italic_ = automatically installed by RubyGems)

Dual-licensed under GPL and Ruby's license.

[![](http://farm1.static.flickr.com/67/219160308_3c11a40f44_m.jpg)](http://www.flickr.com/photo_zoom.gne?id=219160308&size=o)
