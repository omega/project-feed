use MooseX::Declare;
namespace Project::Feed::Bot;

role ::Connection {
    use MooseX::MultiMethods;
    
    use Project::Feed::Types qw/XMLFeedEntry/;
    use Template;
    
    requires 'establish_connection';
    
    # XXX: This is because we can't have some multi here, and some in the implementing class
    requires 'send_message_str';
    
    has 'is_connected' => (is => 'rw', isa => 'Bool', default => 0);
    
    has '_backlog' => (traits => [qw/Array/], is => 'ro', isa => 'ArrayRef', default => sub { [] },
        handles => {
            'queue' => 'push',
            'dequeue' => 'shift',
            'queue_length' => 'count',
            '_get_queued' => 'get',
        }
    );
    method queue_message(Str $str) {
        $self->queue($str);
        while ($self->queue_length > 3) {
            $self->dequeue;
        }
    }

    has '_timer' => (is => 'rw');
    after establish_connection() {
        # We want to send messages at most so and so often, so we don't spam the channel
        $self->_timer(AnyEvent->timer(
            after => 0,
            interval => 5,
            cb => sub {
                $self->timer;
            }
        ));
    }
    
    has 'renderer' => (is => 'ro', builder => '_build_renderer', lazy => 1, handles => [qw/process/]);
    method _build_renderer() {
        # Figure out include path
        my $path = "./assets/" . $self->class;
        
        return Template->new( INCLUDE_PATH => [$path, './assets/']);
    }
    method class() {
        my ($class) = reverse(split("::", ref($self)));
        return $class;
    }
    method render($template, $vars) {
        my $out;
        $self->process($template, $vars, \$out) || confess("Error rendering template $template: " 
            . $self->renderer->error()
        );
        return $out;
    }
    multi method send_message(Object $entry) {
        # should render it using a TT template via a helper on Connection?
        # Guess template based on class name
        
        $self->send_message($self->render(lc($self->class) . ".tt", { entry => $entry }));
    }
    multi method send_message(Str $str) {
        #warn "queue: $str\n";
        # We only queue it, muaha! :)
        
        $self->queue_message($str);
    }
    method demolish_connection() {
        
    }
    
    
    
    method timer() {
        return unless $self->is_connected();
        my $msg = $self->dequeue;
        return unless $msg;
        $self->send_message_str($msg);
        
    }
    
    
}



1;