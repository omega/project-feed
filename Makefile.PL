use inc::Module::Install;

name('Project-Feed');
author('Andreas Marienborg <andreas@startsiden.no>');
version_from('lib/Project/Feed.pm');
license('perl');

requires('MooseX::Declare');
requires('MooseX::SimpleConfig');
requires 'MooseX::MultiMethods';

requires 'MooseX::Getopt';

requires 'AnyEvent::Feed';
requires 'AnyEvent::HTTPD';

requires 'DateTime::Format::Atom';
requires 'HTML::Scrubber';

requires 'YAML::XS';
requires 'Net::SSLeay';

WriteAll;
