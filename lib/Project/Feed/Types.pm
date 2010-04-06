package Project::Feed::Types;

use MooseX::Types
    -declare => [qw/
        BotConnection
        BotConnectionSet
        
        MyFeed
        
        XMLFeedEntry
    /]
;

use MooseX::Types::Moose qw/Object HashRef ArrayRef/;

class_type XMLFeedEntry, { class => 'XML::Feed::Entry::Atom' };

role_type BotConnection, { role => 'Project::Feed::Bot::Connection' };

coerce BotConnection,
    from HashRef,
    via {
        my $class = 'Project::Feed::Bot::Connection::' . delete $_->{module} or die "cannot coerce Connection with a module argument";
        Class::MOP::load_class($class);
        $class->new(%$_);
    }
;

subtype BotConnectionSet, as ArrayRef[BotConnection];
coerce BotConnectionSet,
    from ArrayRef,
    via {
        map {
            $_ = to_BotConnection($_);
        } @$_;
        $_;
    }
;

class_type MyFeed, { class => 'Project::Feed::Bot::Feed' };

coerce MyFeed,
    from HashRef,
    via {
        Class::MOP::load_class('Project::Feed::Bot::Feed');
        Project::Feed::Bot::Feed->new(%$_);
    }
;

1;