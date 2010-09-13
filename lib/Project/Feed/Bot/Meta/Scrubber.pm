use MooseX::Declare;
namespace Project::Feed::Bot;

role ::Meta::Scrubber {
    use HTML::Scrubber;
    has 'scrubber' => (is => 'ro', isa => 'HTML::Scrubber', builder => '_build_scrubber', lazy => 1, handles => [qw/scrub/]);

    method _build_scrubber() {
        HTML::Scrubber->new(allow => []);
    }
    
} 
