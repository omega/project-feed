use MooseX::Declare;

class Project::Feed::Bot::Feed {
    use AnyEvent::Feed;
    use Project::Feed::Types qw(FilterList);
    
    has 'url' => (is => 'ro', isa => 'Str', required => 1);
    has 'interval' => (is => 'ro', isa => 'Int', default => 30);
    has 'on_fetch' => (is => 'ro', isa => 'CodeRef', required => 1);
    has 'username' => (is => 'ro', isa => 'Str', predicate => 'has_username');
    has 'password' => (is => 'ro', isa => 'Str');
    has 'filter'   => (is => 'ro', isa => FilterList, coerce => 1);
    
    has 'conn' => (
        is => 'ro', isa => 'AnyEvent::Feed', lazy => 1, builder => '_build_conn',
        handles => [qw/fetch/],
    );
    
    method _build_conn() {
        AnyEvent::Feed->new(
            url => $self->url,
            interval => $self->interval,
            on_fetch => sub { $self->_got_items(@_) },
            ( $self->has_username ? ( username => $self->username, password => $self->password) : ())
        );
    }
    
    method _got_items($reader, $new_entries, $feed, $error?) {
        if (defined $error) {
            warn "ERROR: $error\n";
            return;
        }
        if ($self->filter and scalar(@$new_entries)) {
            foreach (@$new_entries) {
                foreach my $f (@{$self->filter}) {
                    $f->filter(@$_);
                }
            }
        }
        $self->on_fetch->($reader, $new_entries, $feed);
    }
}
1;
