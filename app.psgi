use Plack::App::File;
my $app = Plack::App::File->new(file => 'output/All_entries.atom')->to_app;
