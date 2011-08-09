use MooseX::Declare;
namespace Project::Feed;

role ::Filter {
    requires 'filter';
}

class ::Filter::JIRA with ::Filter with ::Meta::Scrubber {
    method filter($hash, $entry) {
        # fix title
        my $t = $self->scrub( $entry->title );

        $t =~ s/.*?([A-Z]+-\d+) \((.*)\)/$1: $2/;
        # now to remove some other crap from $t :p

        $entry->title( $t );
    }
}

class ::Filter::AuthorRemove with ::Filter {
    method filter($hash, $entry) {
        my $t = $entry->title;
        my $a = $entry->author;
        $t =~ s/$a\s*//;
        $entry->title( $t );
    }
}

class ::Filter::AuthorMap with ::Filter {
    has 'mapping' => (
        is => 'ro',
        isa => 'HashRef',
        initializer => '_init_mapping',
    );

    method _init_mapping($value, $setter, $attr) {
        # Need to rework value, then set it
        my $new_value = {};
        foreach my $nick (%$value) {
            foreach my $author_name (@{ $value->{$nick} }) {
                $new_value->{$author_name} = $nick;
            }
        }
        $setter->($new_value);
    }

    method filter($hash, $entry) {
        $entry->author( $self->mapping->{ $entry->author })
            if exists $self->mapping->{ $entry->author };
    }
}
