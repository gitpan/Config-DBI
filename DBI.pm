package Config::DBI;

use Config::ApacheFormat;
use Data::Dumper;
use DBI;
use Term::ReadKey;

use diagnostics;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Config::DBI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

my $stdin = '<STDIN>';

our @attr = qw
  (  
   dbi_connect_method
   Warn
   InactiveDestroy
   PrintError
   RaiseError
   HandleError
   ShowErrorStatement
   TraceLevel
   FetchHashKeyName
   ChopBlanks
   LongReadLen
   LongTruncOk
   TaintIn
   TaintOut
   Taint
   Profile

   AutoCommit
  );

our @valid_directives = ( qw(User Pass DSN), @attr ) ;


# Preloaded methods go here.

sub new {

  my $envar = 'DBI_CONF';
  $ENV{$envar} or die "$envar not set";

  my $c = Config::ApacheFormat->new
    (
     valid_directives => \@valid_directives
    );
  $c->autoload_support(1);
  $c->read($ENV{DBI_CONF});
  $c;

}

sub error_handler {

  my ($errstring, $dbh, $retval) = @_;

  warn "e: $errstring d: $dbh r: $retval";

}

sub dummy_error_handler {

  my ($errstring, $dbh, $retval) = @_;

  warn "d_e_h -> e: $errstring d: $dbh r: $retval";

}

sub hash {
  my $self  = shift;
  my $label = shift;
  my $c = __PACKAGE__->new;

  my $block = $c->block(DBI => $label);

  my %A = map {
    defined($block->get($_)) ? ( $_ => $block->get($_) ) : ()
  } @attr;
  


  my @req = qw( DSN);
  for my $req (@req) 
    {
      unless ($block->$req()) {
	die "$req must be defined" 
      }
    }

  if (my $handler = $block->HandleError)
    {
      my $hardref = eval "\\&$handler" ;
      $block->HandleError = $hardref;
    }

  my $Pass;

  if ($block->Pass eq $stdin) 
      {

	# Prevents input from being echoed to screen
	ReadMode 2; 
	print "Enter Password for $label (will not be echoed to screen): ";
	$Pass = <STDIN>;
	if ($Pass) {
	  chomp($Pass) 
	}# else {
	 # undef $Pass
	 #}

	print "\n";
	# Allows input to be directed to the screen again
	ReadMode 0;
      }
    else
      {
	$Pass = $block->Pass
      }

  my %R = 
    (
     User => $block->User,
     Pass => $Pass,
     DSN  => $block->DSN,
     Attr => \%A
    );

}

use vars qw($AUTOLOAD);

sub AUTOLOAD {

  my $self = shift;

  my ($label) = ($AUTOLOAD =~ /([^:]+)$/) ;

  my %c = Config::DBI->hash($label);
  
  DBI->connect($c{DSN}, $c{User}, $c{Pass}, $c{Attr})
    or die $DBI::errstr;

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Config::DBI - Perl extension for blah blah blah

=head1 SYNOPSIS

In .cshrc:

  setenv DBI_CONF dbi.conf

In dbi.conf:

 # Pass maybe a password, or <STDIN> in which case, the password is 
 # is prompted for:

 Pass	     <STDIN>

 # Connect attribute

 # This attribute is a standard part of DBI. Its casing does differ from
 # all other attributes, but I did not create the DBI spec, I am simply
 # following it.

 # Other options for this value are: connect_cached, Apache::DBI::connect

 dbi_connect_method connect 

 # Attributes common to all handles and settable
 # Listed in the order given in the DBI docs:
 # http://search.cpan.org/~timb/DBI-1.38/DBI.pm#METHODS_COMMON_TO_ALL_HANDLES

 Warn 1 
 InactiveDestroy
 PrintError 0 
 RaiseError 0 
 HandleError  Exception::Class::DBI->handler
 ShowErrorStatement 1
 TraceLevel 0
 FetchHashKeyName 0
 ChopBlanks 0
 LongReadLen 0
 LongTruncOk 0
 TaintIn 1 
 TaintOut 0
 # omit Taint (shortcut to set both TaintIn and TaintOut)
 Profile 0
 
 # Attributes for database handles
 # http://search.cpan.org/~timb/DBI-1.38/DBI.pm#Database_Handle_Attributes 

 AutoCommit 0
 
 # Description of a database we would like to connect to

 <DBI basic>
  DSN              dbi:Pg:dbname=mydb
  User             postgres
  AutoCommit  1
 </DBI>

 # Description of another database

 <DBI basic_test>
  DSN   dbi:Pg:dbnamemydb_test
  User  test
  Pass  test
 </DBI>

In Ye Olde Pure Perl Programme:

  use Config::DBI;

  my $dbh = Config::DBI->basic_test;

  my %hash = Config::DBI->hash('basic_test');

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

metaperl, E<lt>metaperl@anfaenger.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by metaperl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
