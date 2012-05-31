use MooseX::Declare;

namespace Project::Feed;
class ::HTTPD {
    use MooseX::MultiMethods;
    has port => (is => 'ro', required => 1, default => 9090);
    has title => (is => 'ro', required => 1, default => 'Project feed');
    has hostname => (is => 'ro', required => 1, default => 'localhost');

    use AnyEvent::HTTPD;
    use XML::Atom::Feed;
    use XML::Atom::Entry;
    use XML::Atom::Link;
    use DateTime::Format::Atom;

    has '_feed' => (traits => [qw/Array/], is => 'ro', isa => 'ArrayRef', default => sub { [] },
        handles => {
            '_queue_entry' => 'unshift',
            'dequeue_entry' => 'pop',
            'feed_queue_length' => 'count',
            '_get_queued_entry' => 'get',
            'entry_queue' => 'elements',
            '_sort_entry_queue' => 'sort_in_place',
        }
    );
    method resort_queue() {
        $self->_sort_entry_queue( sub {
            $_[1]->updated cmp $_[0]->updated
        });
    }
    method queue_entry(Object $entry) {
        $self->_queue_entry($entry);
        $self->resort_queue(); # The one we just added might not be the latest time-wise, so sort after adding
        while ($self->feed_queue_length > 20) {
            $self->dequeue_entry;
        }
    }

    has 'conn' => (
        is => 'ro', lazy => 1, builder => '_setup_httpd',
        handles => [qw/reg_cb/]
    );

    method _setup_httpd() {
        my $h = AnyEvent::HTTPD->new( port => $self->port );

        # Lets also set up some hooks

        $h->reg_cb(
            '/' => sub {
                my ($httpd, $req) = @_;
                # should respond with an atom-feed of our current events
                my $feed = XML::Atom::Feed->new(Version => '1.0');
                $feed->id("project-feed:somefeed");
                $feed->title($self->title);
                my $link = XML::Atom::Link->new(Version => '1.0');
                $link->type('application/atom+xml');
                $link->rel('self');
                $link->href('http://' . $self->hostname . ':' . $self->port . $req->url);

                $feed->add_link($link);
                if ($self->_get_queued_entry(0)) {
                    $feed->updated($self->_get_queued_entry(0)->updated);
                }

                foreach my $e ($self->entry_queue) {
                    $feed->add_entry($e);
                }

                $req->respond([200, 'ok', { 'Content-Type' => 'application/atom+xml' }, $feed->as_xml]);
            }
        );
    }

    method setup() {
        $self->conn;

    }
    multi method send_message(XML::Atom::Entry $entry) {

        my $u = $entry->updated || $entry->published;

        # should streamline $entry->updated here?
        my $dt = DateTime::Format::Atom->parse_datetime($u);
        $entry->updated($dt);
        $self->queue_entry($entry);
    }
    multi method send_message(XML::Feed::Entry::Format::RSS $entry) {
        my $e = $entry->convert('Atom');
        return $self->send_message($e->unwrap);
    }
    multi method send_message(XML::Feed::Entry::Format::Atom $entry) {
        $self->send_message($entry->unwrap);
    }
    multi method send_message(Object $entry) {
        # Should convert to XML::Atom::Entry
        confess("We do not know how to convert from $entry to XML::Atom::Entry");
    }

    has 'is_connected' => (is => 'rw', isa => 'Bool', default => 0);

    method demolish_connection() {

    }
}

1;
