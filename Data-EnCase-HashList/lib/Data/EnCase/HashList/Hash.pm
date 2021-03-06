package Data::EnCase::HashList::Hash;

use 5.12.0;
use warnings;

use base qw{ Class::Accessor };
use Params::Validate qw{ :all };
use File::Basename;
use File::Slurp;
use Scalar::Util qw{ blessed };

our $VERSION = '0.1';

our @reqd_attributes = qw{
	hash
	filename
};

our @attributes = qw {
	fileid
	directory
	filesize
	datemodified
	timemodified
	timezone
	comments
	dateaccessed
	timeaccessed
};

our %template = map { $_ => '' } (@reqd_attributes, @attributes);

=cut

Specification for EnCase hashlist file taken from:

http://www.nsrl.nist.gov/Documents/CreatingHashSetsmanually.pdf

by Sharren Redmond

=cut

sub new {
	my $class = shift;

	validate( @_, { 
		(map { $_ => { type => SCALAR, optional => 0 } } @reqd_attributes),
		(map { $_ => { type => SCALAR, optional => 1 } } @attributes),
	} );

	my %object = %template;
	my %args   = (@_);

	# get default keys and values
	# there are better ways to do this. one day i'll fix it.
	foreach my $key (keys %template) {
		if (defined $args{$key}) {
			$object{$key} = $args{$key};
		}
		else {
			$object{$key} = $template{$key};
		}
	}

	# See File::Basename
	my ($filename, $dirname) = fileparse( $object{filename} );

	if (length $dirname and not length $object{directory}) {
		$object{directory} = $dirname;
		$object{filename}  = $filename;
	}

	$class->follow_best_practice();
	$class->mk_ro_accessors( @reqd_attributes );
	$class->mk_accessors( @attributes );

	return bless \%object, $class;
}

# This returns an array of Hash objects. It is not an object itself.
sub new_from_md5 {
	my $class = shift;

	# It's ugly. I know. But it works, and it's quick. This should cover both
	# Solaris and Linux and seems to work with Darwin.
	return map {
		my $fn = substr $_, 5, (index $_, ')') - 5;
		my ($hash) = (split /\s+/, $_)[-1];
		if ($hash =~ /\//) { $fn = $hash; $hash = substr $_, 0, 32; }

		$class->new( hash => $hash, filename => $fn, );
	} (@_);
}

1;
