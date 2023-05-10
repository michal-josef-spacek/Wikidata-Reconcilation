package Wikidata::Reconcilation;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use LWP::UserAgent;
use Unicode::UTF8 qw(encode_utf8);
use WQS::SPARQL;
use WQS::SPARQL::Result;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# User agent.
	$self->{'agent'} = __PACKAGE__." ($VERSION)";

	# First match mode.
	$self->{'first_match'} = 0;

	# Language.
	$self->{'language'} = 'en';

	# LWP::UserAgent object.
	$self->{'lwp_user_agent'} = undef;

	# Verbose mode.
	$self->{'verbose'} = 0;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'lwp_user_agent'}) {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new(
			'agent' => $self->{'agent'},
		);
	} else {
		if (! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {
			err "Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.";
		}
	}

	$self->{'_q'} = WQS::SPARQL->new(
		'lwp_user_agent' => $self->{'lwp_user_agent'},
	);

	return $self;
}

sub reconcile {
	my ($self, $reconcilation_rules_hr) = @_;

	my @sparql = $self->_reconcile($reconcilation_rules_hr);

	my $ret_hr;
	my %qids;
	if ($self->{'verbose'}) {
		print "SPARQL queries:\n";
	}
	foreach my $sparql (@sparql) {
		if ($self->{'verbose'}) {
			print encode_utf8($sparql)."\n";
		}

		$ret_hr = $self->{'_q'}->query($sparql);
		my @ret = map { $_->{'item'} } WQS::SPARQL::Result->new->result($ret_hr);
		foreach my $ret (@ret) {
			$qids{$ret}++;
		}
		if (@ret && $self->{'first_match'}) {
			last;
		}
	}
	if ($self->{'verbose'}) {
		print "Results:\n";
		foreach my $item (sort keys %qids) {
			print '- '.$item.': '.$qids{$item}."\n";
		}
	}

	return sort keys %qids;
}

sub _reconcile {
	my ($self, $reconcilation_rules_hr) = @_;

	err "This is abstract class. You need to implement _reconcile() method.";
	my @sparql;

	return @sparql;
}

1;

__END__
