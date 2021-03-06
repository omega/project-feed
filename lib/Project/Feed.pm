use MooseX::Declare;

role Project::Feed {


    use AnyEvent;
    use AnyEvent::Strict;
    use Project::Feed::Types qw/MyFeed MyHTTPD FilterList/;
    use Project::Feed::Feed;
    use Project::Feed::HTTPD;

    has 'httpd' => (
        is => 'ro',
        isa => 'Project::Feed::HTTPD',
#        coerce => 1,
        lazy => 1,
        builder => '_build_httpd',
    );
    method _build_httpd() {
        return Project::Feed::HTTPD->new();
    }
    has 'interval' => (is => 'ro', isa => 'Int');

    has 'condvar' => (
        is => 'ro', default => sub { AnyEvent->condvar }, handles => [qw/wait broadcast/]
    );
    has 'filter'   => (is => 'ro', isa => FilterList, coerce => 1);

    has 'feeds' => (is => 'ro', isa => 'Maybe[ArrayRef]', required => 0, predicate => 'has_feeds', );
    has '_feeds' => (
        is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_feed', handles => [qw/fetch/],
    );
    method _build_feed() {
        my @feeds;
        return \@feeds unless $self->has_feeds and ref($self->feeds);
        foreach (@{ $self->feeds }) {
            my $feed = Project::Feed::Feed->new(
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
        $self->httpd->setup();

        if ($self->has_feeds) {
            $self->_feeds;
        }

        $self->wait;


        #$self->broadcast;


    }

    method new_entries($feed_reader, $new_entries, $feed) {
        for (reverse @$new_entries) { # We want oldest first
            my ($hash, $entry) = @$_;
            # Should here send a message
            if ($self->filter) {
                foreach my $f (@{$self->filter}) {
                    $f->filter(@$_);
                }
            }

            $self->httpd->send_message($entry);
        }

    }
}




1;
