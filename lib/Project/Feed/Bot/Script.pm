use MooseX::Declare;

class Project::Feed::Bot::Script with MooseX::SimpleConfig with MooseX::Getopt with Project::Feed::Bot {

    use MooseX::Types::Path::Class qw( File );
    has configfile => (
        is => 'ro',
        isa => File,
        coerce => 1,
        predicate => 'has_configfile',
        default => 'project-bot.yaml',
    );
    
    sub run {
        my ($self) = @_;

        $self->start_bot();
    }
    
}



1;