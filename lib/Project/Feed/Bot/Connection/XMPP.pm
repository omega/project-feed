use MooseX::Declare;
namespace Project::Feed::Bot;
class ::Connection::XMPP with ::Connection {
    use MooseX::MultiMethods;
    
    use AnyEvent::XMPP::Client;
    use AnyEvent::XMPP::Ext::Disco;
    use AnyEvent::XMPP::Ext::MUC;
    
    has 'conn' => (
        is => 'ro', isa => 'AnyEvent::XMPP::Client', lazy => 1, builder => '_build_conn',
        handles => [qw/start reg_cb set_presence add_account get_account/],
    );
    has 'muc'   => ( 
        is => 'ro', lazy => 1, builder => '_build_muc', 
        handles => {
            join_room  => 'join_room',
            get_room   => 'get_room',
            reg_muc_cb => 'reg_cb',
        },
    );
    has 'disco' => ( is => 'ro', lazy => 1, builder => '_build_disco', );
    
    has [qw/jid password room nick/] => (is => 'ro', required => 1);
#    has 'port' => (is => 'ro', default => 5222);

    method BUILD($args) {
    }
    
    method _build_disco() { return AnyEvent::XMPP::Ext::Disco->new }
    method _build_muc() { return AnyEvent::XMPP::Ext::MUC->new( disco => $self->disco ); }
    method _build_conn() {
        my $con = AnyEvent::XMPP::Client->new( debug => 0 );
        $con->add_extension ($self->disco);
        $con->add_extension ($self->muc);
        
        $con;
    }
    
    method establish_connection() {

        $self->set_presence(undef, "I'm a talking bot..");
        
        $self->add_account($self->jid, $self->password, '10.0.0.10', 5222);
        
        $self->_setup_hooks();
        
        $self->start;
        
    }
    method demolish_connection() {
        $self->disconnect;
        
    }
    method _setup_hooks() {
        foreach my $hook_method ( qw/ disconnect session_ready error/ ) {
            $self->reg_cb(
                $hook_method => sub {
                    $self->$hook_method(@_);
                }
            ) if $self->can($hook_method);
        }
        
        # Should hook some debug events I guess :p
        
    }
    method account() {
        return $self->get_account($self->jid);
    }
    method connection() {
        my $acc = $self->account;
        warn "not connected!!\n" unless $acc->is_connected;
        return $acc->connection
    }
    method is_connected() {
        return $self->account->is_connected;
    }
    multi method send_message_str(Str $text) {
        unless ($self->is_connected) {
            warn "XMPP not connected!\n";
            return;
        }
        
        my $room = $self->get_room($self->connection, $self->room);
        
        my $mess = $room->make_message(body => $text)
    }
    
    
    #### HOOKS
    
    method session_ready($client, $acc) {
        print "connected XMPP ;)\n";
        $self->join_room( $acc->connection, $self->room, $self->nick);
        
        $self->reg_muc_cb( message => sub {
            $self->muc_message(@_);
        })
        
    }
        method muc_message($muc, $room, $msg, $is_echo) {
            return if $is_echo;
            #print "Got message: " . $msg->any_body . "\n";
        }
    method error($client, $acc, $error) {
        warn "error: $error\n";
    }
    method disconnect($client, $acc, $host, $port, $message) {
        print "I’m out from $host:$port  :: $message !\n";
    }
    
}