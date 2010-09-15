use MooseX::Declare;

class Project::Feed::Script with MooseX::SimpleConfig with MooseX::Getopt with Project::Feed {

    use Moose::Util::TypeConstraints;
    class_type 'XML::Atom::Entry', { class => 'XML::Atom::Entry' };
    class_type 'XML::Feed::Entry::Format::RSS', { class => 'XML::Feed::Entry::Format::RSS' };
    class_type 'XML::Feed::Entry::Format::Atom', { class => 'XML::Feed::Entry::Format::Atom' };

    use MooseX::Types::Path::Class qw( File );
    has configfile => (
        is => 'ro',
        isa => File,
        coerce => 1,
        predicate => 'has_configfile',
        default => 'etc/project-feed.yaml',
    );
    
    sub run {
        my ($self) = @_;

        $self->start_bot();
    }
    
}



1;