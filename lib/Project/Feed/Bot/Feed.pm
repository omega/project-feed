use MooseX::Declare;

class Project::Feed::Bot::Feed {
    use AnyEvent::Feed;
    has 'url' => (is => 'ro', isa => 'Str', required => 1);
    has 'interval' => (is => 'ro', isa => 'Int', default => 30);
    has 'on_fetch' => (is => 'ro', isa => 'CodeRef', required => 1);
    has 'conn' => (
        is => 'ro', isa => 'AnyEvent::Feed', lazy => 1, builder => '_build_conn',
        handles => [qw/fetch/],
    );
    method _build_conn() {
        AnyEvent::Feed->new(
            url => $self->url,
            interval => $self->interval,
            on_fetch => $self->on_fetch,
        );
    }
}
1;
