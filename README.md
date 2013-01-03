
The Cheat
=========

![The Cheat Logo](http://chazmcgarvey.github.com/thecheat/img/thecheat.png)

This is the legendary universal game trainer for Mac OS X.  This program
enables you to search the memory address space of another running process and
even do a little covert *tweaking*.  The most apparent (and awesome)
application for this gem is changing the values of interesting variables
within games in real time.  Yeah, that might be considered cheating, which is
where this little program gets its name.  Here is a rundown of the most
notable features:

* Search for many types of variables, including strings, integers, and
  floating point numbers.
* Bonjour-aware networking allows you to cheat remotely from another computer.
* File saving and opening.  Once you find a cheat, save it and maybe it will
  work next time.

![Screenshot](http://chazmcgarvey.github.com/thecheat/img/screenshot1.png)

License
-------

This software is licensed according to the terms and conditions of the
[BSD 2-Clause License](http://www.opensource.org/licenses/bsd-license.php).
Please see the COPYING file for more information.

Download
--------

The latest and greatest release is
[The Cheat 1.2.5](http://chazmcgarvey.github.com/thecheat/thecheat-1.2.5.dmg),
an Intel/PPC binary released on 22 Nov 2010.
Older releases are available at <ftp://ftp.brokenzipper.com/pub/mac/thecheat/>.

    Size: 711K
     MD5: 429b54298b804bc5e9343ac179eba428

Getting Started
---------------

This software is not necessarily easy to use if you are new and inexperienced.
The target audience for this software includes software developers and
hardcore gamers.  It will help if you know a few things about bits and bytes.
Nevertheless, the documentation available is pretty good, so if you have the
desire and a little bit of time to learn some new things, you won't have any
problems.

The Cheat has a built-in help document.  It reads like a user manual, but it
isn't very long and has a lot of useful information to get new users started
quickly, so go read it.  You will find it from the application's `Help` menu.

If you are using an Intel Mac, reports suggest that you must set a certain
kernel option in order for The Cheat to work.  Open up `Terminal.app` and
enter this, typing your password when prompted:

    sudo sysctl -w kern.tfp.policy=1

![Screenshot](http://chazmcgarvey.github.com/thecheat/img/screenshot2.jpg)

Alternatives
------------

If thecheat just doesn't do it for you, there are a couple clones that you can
try.  I've never used them, but they could be more up-to-date and better
supported by their respective project maintainers:

* [iHaxGamez](http://www.ihaxgamez.com/)
* [Bit Slicer](http://zorg.tejat.net/programs#bitslicer)

Frequently Asked Questions
--------------------------

### Is it possible to cheat multi-player games?

Maybe.  Probably not.  You can try, but most modern servers have consistency
checks in order to detect cheating.  Some server operators have low tolerance
for multi-player cheating, so it's possible to get your account banned if
you're not careful.  Basically, I don't recommend cheating in a multi-player
setting.  If you choose to try, you do so at your own peril.

### Can I cheat online Flash games?

Generally, yes.  Again, it depends on the exact nature of the program and what
you're trying to accomplish.  There are several video tutorials on YouTube
demonstrating some Flash games being cheated; search around for inspiration.

### Why do my saved cheats not work the next time I try to use them?

Sometimes they will, sometimes they won't.  It will work as long as the
variables have the same addresses every time the program runs.  The older the
program, the higher the chance that this is true and that saved cheats will
work.  If you want the technical answer, read on.  It depends on the game and
where the variable exists in the address space of the process you're cheating.
If the variable is static, global, or even on the stack (and assuming the
address space isn't subject to randomization for security purposes), then the
addresses may remain the same each time.  On the other hand, variables that
are created on the heap are subject to pseudo-random placement by the
allocator, so their addresses may change unexpectedly, even while the program
is running.

There's not much you can do about it if the variable's address changes.
You've just got to search for it each time.  Bummer!

### Can I apply multiple cheats at the same time?

Yep.  Once you add a variable, it will appear in the list if you're in cheat
mode.  To add more cheats, just go back to search mode, clear the current
search, and look for the next one.  Once you've found all the cheats you want,
you can apply one or more cheats from the cheat mode.

### Why do I need to authenticate as an Administrator to use The Cheat?

It used to be possible back around the time of Mac OS X 10.3 or so to use the
virtual memory "backdoor" functions without Admin rights.  Those were good
days.  Fast-forward to today: These newfangled versions of Mac OS X (perhaps
starting with 10.4 or 10.5?) don't trust regular users with the kind of power
The Cheat is meant to provide.  So that's it; you have to authenticate in
order to use the virtual memory functions provided by the kernel, and that's
the only reason.  The Cheat certainly doesn't do anything devious with those
elevated privileges, and the source code is open in case you want to check
that for yourself.

### Why do my searches keep returning zero search results?

Maybe the variable you're searching for is not the type you expect, or maybe
its value is masked or obfuscated in a way that is making it hard to find.  If
you are fluent in assembly code and competent with a debugger, you may be able
to find the code that reads or writes the variable you're looking for.  In
that case, the debugger should be able to tell you where the variable is.
Almost anything can be done, given enough time, the right tools, and the right
knowledge.

