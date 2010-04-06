use MooseX::Declare;
namespace Project::Feed::Bot;

role ::Connection {
    use MooseX::MultiMethods;
    
    use Project::Feed::Types qw/XMLFeedEntry/;
    requires 'establish_connection';
    
    # XXX: This is because we can't have some multi here, and some in the implementing class
    requires 'send_message_str';


    multi method send_message(Object $entry) {
        # should render it using a TT template via a helper on Connection?
        $self->send_message($entry->title);
    }
    multi method send_message(Str $str) {
        $self->send_message_str($str);
    }
    method demolish_connection() {
        
    }
    
}



1;