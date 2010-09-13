use MooseX::Declare;
namespace Project::Feed::Bot;
class ::Connection::XMPP with ::Connection with ::Meta::Scrubber {
    use MooseX::MultiMethods;
    
    use AnyEvent::XMPP::Client;
    use AnyEvent::XMPP::Ext::Disco;
    use AnyEvent::XMPP::Ext::MUC;
    
    
    has 'test_fail_bit' => (is => 'ro', isa => 'Str', default => 'BROKEN TESTS');
    has 'room_subject' => (is => 'rw', isa => 'Str');
    
    has 'conn' => (
        is => 'ro', isa => 'AnyEvent::XMPP::Client', lazy => 1, builder => '_build_conn',
        handles => [qw/start reg_cb set_presence add_account get_account/],
    );
    has 'muc'   => ( 
        is => 'ro', lazy => 1, builder => '_build_muc', 
        handles => {
            join_room  => 'join_room',
            '__get_room'   => 'get_room',
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
        my $con = AnyEvent::XMPP::Client->new( debug => 1 );
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
    multi method send_message_str(Str $rich) {
        # need to make one that is clean, and one that is rich.. $rich is presumed to be rich now.
        
        my $text = $self->scrub($rich);
        warn "scrubbed: $text\n";
        unless ($self->is_connected) {
            #warn "XMPP not connected!\n";
            return;
        }
        
        my $room = $self->get_room();
        my $mess = $room->make_message(body => $text);
        $mess->append_creation(sub {
                my ($w) = @_;
                $w->addPrefix('http://www.w3.org/1999/xhtml' => '');
                $w->startTag (['http://www.w3.org/1999/xhtml', 'html']);
                    #$w->addPrefix('http://www.w3.org/1999/xhtml' => '');
                    $w->startTag ('body');
                        $w->raw($rich);
                    $w->endTag;
                    #$w->removePrefix('http://www.w3.org/1999/xhtml');
                $w->endTag;
                $w->removePrefix('http://www.w3.org/1999/xhtml');
          });
        $mess->send;
    }
    
    method topic_fail() {
        # for now just send a message
        return unless ($self->is_connected);
        
        my $room = $self->get_room();
        $room->change_subject($self->test_fail_bit . " - " . $self->room_subject);
    }
    method topic_recover() {
        return unless $self->is_connected;
        my $room = $self->get_room();
        # 
        my $subj = $self->room_subject;
        my $fail = $self->test_fail_bit;
        
        $subj =~ s/^$fail - //;
        
        $room->change_subject($subj);
    }
    
    method get_room() {
        my $room = $self->__get_room($self->connection, $self->room);
        
    }
    
    #### HOOKS
    
    method session_ready($client, $acc) {
        print "connected XMPP ;)\n";
        $self->is_connected(1);
        $self->join_room( $acc->connection, $self->room, $self->nick);
        
        $self->reg_muc_cb( 
            message => sub { $self->muc_message(@_); },
            subject_change => sub { $self->subject_change(@_); },
        );
        
    }
        method muc_message($muc, $room, $msg, $is_echo) {
            return if $is_echo;
            #print "Got message: " . $msg->any_body . "\n";
        }
        method subject_change($much, $room, $msg, $is_echo) {
            return if $is_echo; # we don't want to do anything if WE set the subject, right?

            # our subject is in $msg->any_subject
            my $new = $msg->any_subject;
            #my $fail = $self->test_fail_bit;
            
            $self->room_subject($new);
        }
    method error($client, $acc, $error) {
        warn "error: $error\n";
    }
    method disconnect($client, $acc, $host, $port, $message) {
        print "I’m out from $host:$port  :: $message !\n";
    }
    
}