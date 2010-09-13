use MooseX::Declare;

role Project::Feed::Bot {
    
    use Moose::Util::TypeConstraints;
    class_type 'XML::Atom::Entry', { class => 'XML::Atom::Entry' };
    class_type 'XML::Feed::Entry::Format::RSS', { class => 'XML::Feed::Entry::Format::RSS' };
    class_type 'XML::Feed::Entry::Format::Atom', { class => 'XML::Feed::Entry::Format::Atom' };
    
    use AnyEvent;
    use AnyEvent::Strict;
    use Project::Feed::Types qw/BotConnectionSet MyFeed Topic/;
    use Project::Feed::Bot::Feed;
    use Project::Feed::Bot::Topic;
    
    has 'connections' => (
        traits => [qw/Array/],
        is => 'ro',
        isa => BotConnectionSet,
        coerce => 1,
        handles => {
            'all_connections' => 'elements'
        }
    );
    has 'interval' => (is => 'ro', isa => 'Int');
    
    has 'condvar' => (
        is => 'ro', default => sub { AnyEvent->condvar }, handles => [qw/wait broadcast/] 
    );
    
    has 'topic' => (is => 'ro', isa => Topic, coerce => 1, required => 0, predicate => 'has_topic', );
    
    has 'feeds' => (is => 'ro', isa => 'Maybe[ArrayRef]', required => 0, predicate => 'has_feeds', );
    has '_feeds' => (
        is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_feed', handles => [qw/fetch/],
    );
    method _build_feed() {
        my @feeds;
        return \@feeds unless $self->has_feeds and ref($self->feeds);
        foreach (@{ $self->feeds }) {
            my $feed = Project::Feed::Bot::Feed->new(
                url => delete $_->{url},
                interval => delete ($_->{interval}) || $self->interval,
                on_fetch => sub {
                    $self->new_entries(@_);
                },
                %$_, # Lets just bring in everything else!
            );
            $feed->conn; # XXX: ugly, but I'm tired!
            push(@feeds, $feed);
        }
        return \@feeds;
    }
    

    method start_bot() {
        # Need to make sure all connections get connected, and set up properly
        foreach my $con ($self->all_connections) {
            $con->establish_connection();
        }
        if ($self->has_feeds) {
            $self->_feeds;
        }

        # Lets set up our topic
        if ($self->has_topic) {
            $self->topic->on_fail(sub {
                $self->topic_fail
            });
            $self->topic->on_unfail(sub {
                $self->topic_recover
            });
        }
        
        $self->wait;
        
        
        #$self->broadcast;
        
        
    }

    method new_entries($feed_reader, $new_entries, $feed) {
        for (reverse @$new_entries) { # We want oldest first
            my ($hash, $entry) = @$_;
            # Should here send a message
            foreach my $con ($self->all_connections) {
                $con->send_message($entry)
            }
        }
        
    }
    
    method topic_fail() {
        foreach my $con ($self->all_connections) {
            $con->topic_fail() if $con->can('topic_fail');
        }
    }
    method topic_recover() {
        foreach my $con ($self->all_connections) {
            $con->topic_recover() if $con->can('topic_recover');
        }
    }
}




1;
