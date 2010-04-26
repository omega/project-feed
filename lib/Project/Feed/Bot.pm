use MooseX::Declare;

role Project::Feed::Bot {
    
    use Moose::Util::TypeConstraints;
    class_type 'XML::Atom::Entry', { class => 'XML::Atom::Entry' };
    class_type 'XML::Feed::Entry::Format::RSS', { class => 'XML::Feed::Entry::Format::RSS' };
    class_type 'XML::Feed::Entry::Format::Atom', { class => 'XML::Feed::Entry::Format::Atom' };
    
    use AnyEvent;
    use AnyEvent::Strict;
    use Project::Feed::Types qw/BotConnectionSet MyFeed/;
    use Project::Feed::Bot::Feed;
    
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
    
    has 'feeds' => (is => 'ro', isa => 'ArrayRef', required => 1, );
    has '_feeds' => (
        is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_feed', handles => [qw/fetch/],
    );
    method _build_feed() {
        my @feeds;
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
        $self->_feeds;
        
        $self->wait;
        
        #$self->broadcast;
        
        
    }

    method new_entries($feed_reader, $new_entries, $feed, $error?) {
        if (defined $error) {
            warn "ERROR: $error\n";
            return;
        }
        warn "new: " . scalar(@$new_entries) . "\n" if scalar(@$new_entries);
        for (reverse @$new_entries) { # We want oldest first
            my ($hash, $entry) = @$_;
            # Should here send a message
            foreach my $con ($self->all_connections) {
                $con->send_message($entry)
            }
        }
        
    }
}




1;
