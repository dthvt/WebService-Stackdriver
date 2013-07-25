package WebService::Stackdriver;

use 5.008000;
use strict;
use warnings;

use Carp;
use DateTime;
use LWP::UserAgent;
use JSON;

#use Data::Dumper qw(Dumper);

our $VERSION = '1.0.1';

=head1 NAME

WebService::Stackdriver - Perl extension for Stackdriver web API

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
  if (not $ret) { 
      print "Submission failed: ", $sd->last_response->code,
	      " ", $sd->last_response->message,  "\n",
		  $sd->last_response->decoded_content, "\n";
  }
  $ret = $sd->submit_code_deploy(
	      revision_id => '87230611cdc7e5ff7723a91e715367c553ad1115',
          deployed_by => 'dhagan',
	      deployed_to => 'production',
	      repository => 'MyProject',
  );

=head1 DESCRIPTION

WebService::Stackdriver provides access to the custom metrics and code deployment 
notification API for Stackdriver.

=head1 USAGE

You need a Stackdriver account API key in order to use this module.  All data types 
used to communicate with Stackdriver are described in the Stackdriver documentation.
Please see 
L<http://feedback.stackdriver.com/knowledgebase/articles/181488-sending-custom-metrics-to-the-stackdriver-system>
and 
L<http://feedback.stackdriver.com/knowledgebase/articles/212917-sending-code-deploy-events-to-stackdriver> 
for details on how to send custom data to Stackdriver.

=head1 METHODS

WebRequest::Stackdriver uses an object oriented interface.

=head2 new

Requires an C<apikey> named argument. The C<apikey> argument should be your API key from Stackdriver.

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

####
# ua
#
# Accessor for the LWP::UserAgent object.
#
sub ua {
	return $_[0]->{ua};
}

####
# validate_date
#
# Internal function to validate the user supplied data structure meets 
# Stackdriver requirements.  Uses Carp to report any validation issues.
#
# Returns boolean.
#
sub validate_data {
	my ($self, $data) = @_;
	if (ref $data eq "HASH") {
		$data = [ $data ];
	}
	foreach my $d (@$data) {
		do { carp "name is a required data element"; return 0; } unless exists $d->{name};
		do { carp "value is a required data element"; return 0; } unless exists $d->{value};
		do { carp "collected_at is a required data element"; return 0; } unless exists $d->{collected_at};
	}
	return 1;
}

=head2 submit_metric

Requires a named argument named C<data>. The C<data> argument must be either a hashref 
(for a single data point) or an arrayref (for multiple data points). Each data
point must include keys named C<name>, C<value>, and C<collected_at>.  You can also include
an optional C<instance> key, which must match an instance name in your Stackdriver
dashboard.

See L<http://feedback.stackdriver.com/knowledgebase/articles/181488-sending-custom-metrics-to-the-stackdriver-system> 
for details on permitted values for each of these keys.

Returns boolean to indicate whether submission was accepted by the Stackdriver API.

=cut

sub submit_metric {
	my ($self, %args) = @_;
	
	croak "data required" unless defined $args{data};
	croak "data should be reference" unless (ref($args{data}) eq "ARRAY" or ref($args{data}) eq "HASH");
	croak "data failed validation" unless $self->validate_data($args{data});

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

	$self->{last_response} = $resp;
	
	#print Dumper $resp;
	
	return $resp->is_success;
}

=head2 submit_code_deploy

Submits a code deployment notification to Stackdriver. Requires a named argument named C<revision_id>. 
It may also have optional C<deployed_by>, C<deployed_to>, and C<repository> keys.

See L<http://feedback.stackdriver.com/knowledgebase/articles/212917-sending-code-deploy-events-to-stackdriver> 
for details on each of these keys.

Returns boolean to indicate whether submission was accepted by the Stackdriver API.

=cut

sub submit_code_deploy {
	my ($self, %args) = @_;
	
	croak "revision_id argument must exist" unless exists $args{revision_id};
	
	my $timestamp = DateTime->now->epoch;
	my $proto_version = 1;
	my $api_url = 'https://custom-gateway.stackdriver.com/v1/deployevent';

	my $resp = $self->ua->post($api_url,
		Content => encode_json(
			\%args,
		),
	);
	
	$self->{last_response} = $resp;
	
	#print Dumper $resp;
	
	return $resp->is_success;
}

=head2 last_response

Returns the cached L<HTTP::Response> object from the last request to the Stackdriver API.
This can be used to see additional detail if one of your requests fails.

=cut

sub last_response {
	return $_[0]->{last_response};
}

=head1 SEE ALSO

For details on Stackdriver API usage, see L<http://feedback.stackdriver.com/knowledgebase/articles/181488-sending-custom-metrics-to-the-stackdriver-system> 
and L<http://feedback.stackdriver.com/knowledgebase/articles/212917-sending-code-deploy-events-to-stackdriver>.

For development status and bug reports, please see L<https://github.com/dthvt/WebService-Stackdriver>.

=head1 AUTHOR

Daniel Hagan, E<lt>daniel@kickidle.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Daniel Hagan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;