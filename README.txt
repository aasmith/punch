= punch

* http://github.com/aasmith/punch

== DESCRIPTION:

Punch manipulates, displays, saves and/or submits your ADP Enterprise
eTime time cards.

== FEATURES/PROBLEMS:

 * Displays your timecard.
 * Adds stuff to your timecard.
 * Saves your timecard.
 * Submits it for approval.

Timecards seem to be pre-populated with hours, so punch will add the
missing department code, as set in ~/.punch.yaml.

== SYNOPSIS:

  $ punch                  # First run will initialize your config file.
  $ vim ~/.punch.yaml      # Edit config
  $ punch                  # Displays your timecard to be submitted.
  $ punch --submit=save    # Saves your timecard to ADP.
  $ punch --submit=approve # Sends your timecard to be approved.

If you need to share your config will colleagues, remove the password!

  $ grep -v ^:password: ~/.punch.yaml 

== INSTALL:

  $ git clone git://github.com/aasmith/punch
  $ cd punch
  $ bundle install
  $ rake gem
  $ gem install pkg/punch*.gem

== REQUIREMENTS:

* mechanize

== LICENSE:

Copyright (c) 2014 Andrew A. Smith <andy@tinnedfruit.org>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
