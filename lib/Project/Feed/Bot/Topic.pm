use MooseX::Declare;

class Project::Feed::Bot::Topic {
    use AnyEvent::HTTP;
    
    
    has 'url' => (is => 'ro', isa => 'Str', required => 1);
    has 'fail' => (is => 'ro', isa => 'Str|RegexpRef', default => sub { qr/FAIL/i });
    has 'on_fail' => (is => 'rw', isa => 'CodeRef', required => 0 );
    has 'on_unfail' => (is => 'rw', isa => 'CodeRef', required => 0 );
    has 'in_fail' => (is => 'rw', isa => 'Bool', default => 0);
    has '_timer' => (is => 'rw');
    method BUILD(HashRef $args) {
        # We want to send messages at most so and so often, so we don't spam the channel
        $self->_timer(AnyEvent->timer(
            after => 0,
            interval => 5,
            cb => sub {
                http_get($self->url, sub {
                    $self->content(@_);
                });
            }
        ));
    }

    method content($body, HashRef $headers) {
        return unless $body;
#        warn "BODY: $body " . $self->in_fail;
        if (!$self->in_fail and $body =~ $self->fail) {
            # We should send out our event, that hopefully our XMPP can listen to
            $self->in_fail(1);
            $self->on_fail->();
        } elsif ($self->in_fail and $body !~ $self->fail) {
            $self->in_fail(0);
            $self->on_unfail->();
        }
    }
}

1;