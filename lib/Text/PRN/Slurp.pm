package Text::PRN::Slurp;

use strict;
use warnings;

use IO::File;
use IO::Scalar;

=head1 NAME

Text::PRN::Slurp - Parse and read .PRN File Extension

=head1 VERSION

Version 1.04

=cut

use vars qw/$VERSION/;

$VERSION = 1.04;


=head1 SYNOPSIS

PRN, short name for Printable, is used as the file extension for files padded with space characters.

    use Text::PRN::Slurp;

    my $slurp = Text::PRN::Slurp->new->load(
        'file' => $file,
        'file_headers' => [ q{A}, q{B}, q{C}, q{D} ]
    );

=head1 USAGE

    use Text::PRN::Slurp;

    my $data = Text::PRN::Slurp->load(file       => $filename   ,file_headers => ['A','B','C']  [,%options]);
    my $data = Text::PRN::Slurp->load(filehandle => $filehandle ,file_headers => ['A','B','C']  [,%options]);
    my $data = Text::PRN::Slurp->load(string     => $string     ,file_headers => ['A','B','C']  [,%options]);

=head1 EXPORT

=head2 new

    Constructors method

=cut

sub new {
    my ( $class ) = @_;
    return bless {}, $class;
}

=head2 load

    my $data = Text::PRN::Slurp->load(file       => $filename   ,file_headers => ['A','B','C']);
    my $data = Text::PRN::Slurp->load(filehandle => $filehandle ,file_headers => ['A','B','C']);

    Returns an arrayref of hashrefs. Its fields are used as the keys for each of the hashes.

=cut

sub load {
    my ( $self, %opt ) = @_;

    my %default = ( binary => 1 );
    %opt = (%default, %opt);

    if ( !defined $opt{'file_headers'} ) {
        die "File headers is needed to parse file";
    }
    if ( ref $opt{'file_headers'} ne 'ARRAY' ) {
        die "File headers needed to be an array";
    }

    if ( !defined $opt{'filehandle'} &&
         !defined $opt{'file'} && 
         !defined $opt{'string'} 
    ) {
        die "Need either a file, filehandle or string to work with";
    }

    my $io;
    if ( defined $opt{'filehandle'} ) {
        $io = $opt{'filehandle'};
        delete $opt{'filehandle'};
    }

    if ( defined $opt{'file'} ) {
        $io = new IO::File;
        open( $io, '<:encoding(UTF-8)', $opt{'file'} )
            or die "Could not open $opt{file} $!";
        delete $opt{'file'};
    }

    if ( defined $opt{'string'} ) {
        $io = IO::Scalar->new( \$opt{'string'} );
        delete $opt{'string'};
    }

    return _from_io_handler($io,\%opt);
}

sub _from_io_handler {
    my ( $io, $opt_ref ) = @_;

    my @file_header = @{ $opt_ref->{'file_headers'} };
    my ( %col_length_map, @file_data_as_array);

    my $row_count = 1;
    while (my $row = <$io>) {
        chomp $row;
        ## Assume first row is heading
        if ( $row_count == 1 ) {
            foreach my $col_heading ( @file_header ) {
                $row =~m{($col_heading\s+)}i;
                $row =~m{($col_heading\s?)}i if not $1;
                if ( $1 ) {
                    my $table_column = $1;
                    my $table_column_length = length $table_column;
                    # remove leading and trailing spaces
                    $table_column =~s{^\s+|\s+$}{}g;
                    $col_length_map{ $table_column } = $table_column_length;
                }
                else {
                    warn q{Columns doesn't seems to be matching};
                }
            }
        }
        else {
            my $string_offset = 0;
            my %extracted_row_data;
            for( my $col_index=0; $col_index<=$#file_header; $col_index++ ) {
                my $col = $file_header[$col_index];
                my $col_length = $col_length_map{ $col } || 0;
                if ( $col_length ) {
                    my $col_data = substr $row, $string_offset, $col_length;
                    # remove leading and trailing spaces
                    $col_data =~s{^\s+|\s+$}{}g;
                    $extracted_row_data{ $col } = $col_data;
                    $string_offset += $col_length;
                }
            }

            push @file_data_as_array, \%extracted_row_data;
        }
        $row_count++;
    }

    return \@file_data_as_array;
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-prn-slurp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-PRN-Slurp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::PRN::Slurp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-PRN-Slurp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-PRN-Slurp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-PRN-Slurp>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-PRN-Slurp/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Rakesh Kumar Shardiwal.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Text::PRN::Slurp
