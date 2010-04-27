use inc::Module::Install;

name('Project-Feed');
author('Andreas Marienborg <andreas@startsiden.no>');
version_from('lib/Project/Feed.pm');
license('perl');

requires('MooseX::Declare');
requires('MooseX::SimpleConfig');
requires 'MooseX::MultiMethods';

requires 'AnyEvent::Feed';
requires 'AnyEvent::XMPP';
requires 'AnyEvent::HTTPD';
requires 'AnyEvent::IRC';

