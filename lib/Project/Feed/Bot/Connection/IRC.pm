use MooseX::Declare;
namespace Project::Feed::Bot;
# A lot of this is based on Bot::IRC::Lite:
#    http://github.com/dann/p5-bot-irc-lite/
class ::Connection::IRC with ::Connection {
    use MooseX::MultiMethods;
    
    use AnyEvent::IRC::Client;
    
    has 'conn' => (
        is => 'ro', default => sub {AnyEvent::IRC::Client->new},
        handles => [qw/reg_cb send_srv send_chan/]
    );
    
    has [qw/server channel/] => (is => 'ro', required => 1);
    has 'port' => (is => 'ro', default => 6667);
    has 'options' => (is => 'ro', isa => 'HashRef');
    method BUILD($args) {
        $self->_setup_hooks();
    }
    method establish_connection() {
        # Can't delegate connect, as it is a signal method
        $self->conn->connect( $self->server, $self->port, $self->options );
        
        $self->send_srv( "JOIN", $self->channel );
    }
    method demolish_connection() {
        $self->disconnect;
        
    }
    method _setup_hooks() {
        foreach my $hook_method ( qw/privatemesg publicmsg connect disconnect/ ) {
            $self->reg_cb(
                $hook_method => sub {
                    $self->$hook_method(@_);
                }
            ) if $self->can($hook_method);
        }
        
        # Should hook some debug events I guess :p
        
    }
    multi method send_message_str(Str $text) {
        $self->send_chan( $self->channel, "NOTICE", $self->channel, $text );
    }
    
    ## All our hooked methods
    
    #method privatemsg($nick, $ircmsg) {
    #}

    #method publicmsg($channel, $ircmsg) {
    #}

    method connect($con, $error?) {
        if ( defined $error ) {
            print "Couldn't connect to server: $error\n";
            return;
        }
        print "connected ;)\n";
    }

    method disconnect() {
        print "I’m out!\n";
    }

    method registered() {
        $self->connection->enable_ping( 60 );
        print "I’m in!\n";
    }

    
    
}



1;