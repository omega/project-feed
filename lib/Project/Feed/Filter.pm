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