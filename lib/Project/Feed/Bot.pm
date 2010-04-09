use MooseX::Declare;

role Project::Feed::Bot {
    
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
    
    has 'condvar' => (
        is => 'ro', default => sub { AnyEvent->condvar }, handles => [qw/wait broadcast/] 
    );
    
    has 'feed' => (is => 'ro', isa => 'HashRef', required => 1, );
    has '_feed' => (
        is => 'ro', isa => MyFeed, lazy => 1, builder => '_build_feed', handles => [qw/fetch/],
    );
    method _build_feed() {
        my $feed = Project::Feed::Bot::Feed->new(
            url => $self->feed->{url},
            interval => $self->feed->{interval},
            on_fetch => sub {
                $self->new_entries(@_);
            },
        );
        $feed->conn; # XXX: ugly, but I'm tired!
        $feed;
    }
    

    method start_bot() {
        # Need to make sure all connections get connected, and set up properly
        foreach my $con ($self->all_connections) {
            $con->establish_connection();
        }
        $self->_feed;
        
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
