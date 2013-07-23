package WebService::Stackdriver;

use 5.008000;
use strict;
use warnings;

use Carp;
use DateTime;
use LWP::UserAgent;
use JSON;

use Data::Dumper qw(Dumper);

our $VERSION = '0.01';

=head1 NAME

WebService::Stackdriver - Perl extension for Stackdriver

=head1 SYNOPSIS

  use WebService::Stackdriver;
  my $sd = WebService::Stackdriver->new(apikey => 'keyhere');
  my $ret = $sd->submit_metric(
      data => [
	      {
		      name => 'custom.metric1',
			  value => 3.14159,
			  collected_at => DateTime->now->epoch(),
          },
	      {
		      name => 'custom.metric2',
			  value => 3.14159,
			  instance => 'aws-host-001',
			  collected_at => DateTime->now->epoch(),
          },
      ],
  );
  if (not $ret) { die "Failed to submit metric" }
		  

=head1 DESCRIPTION

Stub documentation for WebService::Stackdriver, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=cut

sub new {
	my ($class, %args) = @_;
	
	croak "apikey required" unless defined $args{apikey};
	
	my $ua = LWP::UserAgent->new;
	$ua->default_header(
		'Content-type' => 'application/json',
		'X-stackdriver-apikey' => $args{apikey},
	);
	
	return bless {
		apikey => $args{apikey},
		ua => $ua,
	}, (ref $class ? ref $class : $class);
}

sub ua {
	return $_[0]->{ua};
}

sub submit_metric {
	my ($self, %args) = @_;
	
	croak "data required" unless defined $args{data};
	croak "data should be reference" unless (ref($args{data}) eq "ARRAY" or ref($args{data}) eq "HASH");
	#croak "data failed validation" unless $self->validate_data($args{data});

	my $timestamp = DateTime->now->epoch;
	my $proto_version = 1;
	my $api_url = 'https://custom-gateway.stackdriver.com/v1/custom';
	my $data = $args{data};
	
	my $resp = $self->ua->post($api_url, 
		Content => encode_json({
			timestamp => $timestamp,
			proto_version => $proto_version,
			data => $data,
		}),
	);
	
	print Dumper($resp);
	
	return $resp->is_success;
}

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;