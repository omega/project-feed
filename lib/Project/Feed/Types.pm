package Project::Feed::Types;

use MooseX::Types
    -declare => [qw/
        MyHTTPD
        
        MyFeed
        
        Filter
        FilterList
        
        XMLFeedEntry
    /]
;

use MooseX::Types::Moose qw/Undef Object HashRef ArrayRef/;

class_type XMLFeedEntry, { class => 'XML::Feed::Entry::Atom' };

class_type MyHTTPD, { role => 'Project::Feed::HTTPD' };

coerce MyHTTPD,
    from HashRef,
    via {
        Project::Feed::HTTPD->new(%$_);
    }
;


class_type MyFeed, { class => 'Project::Feed::Feed' };

coerce MyFeed,
    from HashRef,
    via {
        Class::MOP::load_class('Project::Feed::Feed');
        Project::Feed::Feed->new(%$_);
    }
;

role_type Filter, { role => 'Project::Feed::Filter' };
coerce Filter,
    from HashRef,
    via {
        my $class = 'Project::Feed::Filter::' . delete $_->{type} or die "cannot coerce Filter without a type argument";
        Class::MOP::load_class('Project::Feed::Filter');
        $class->new(%$_);
    }
;

subtype FilterList, as ArrayRef[Filter];
coerce FilterList,
    from ArrayRef,
    via {
        map {
            $_ = to_Filter($_);
        } @$_;
        $_;
    }
;
1;