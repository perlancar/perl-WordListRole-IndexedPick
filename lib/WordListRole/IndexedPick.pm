package WordListRole::IndexedPick;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict 'subs', 'vars';
use warnings;
use Role::Tiny;

sub _index_pos {
    # why is still this necesary? does Role::Tiny enforce strict?
    no strict 'refs';

    my $self = shift;
    my $class = $self->{orig_class} || ref($self);
    my $fh = \*{"$class\::DATA"};
    seek $fh, ${"$class\::DATA_POS"}, 0;

    my @pos;
    while (1) {
        push @pos, tell $fh;
        my $word = <$fh>;
        last unless defined $word;
    }
    $self->{_index_pos} = \@pos;
}

sub pick {
    # why is still this necesary? does Role::Tiny enforce strict?
    no strict 'refs';

    my ($self, $n, $allow_duplicates) = @_;

    $n = 1 if !defined $n;
    die "Please don't pick too many items" if $n >= 10_000;

    my $class = $self->{orig_class} || ref($self);
    my $fh = \*{"$class\::DATA"};

    $self->_index_pos unless $self->{_index_pos};

    my (%pos, @pos);
    my $iter = 0;
    while (1) {
        if ($allow_duplicates) {
            last if @pos >= $n;
        } else {
            last if keys(%pos) >= $n;
        }
        my $pos = int(rand() * scalar(@{ $self->{_index_pos} }));
        if ($allow_duplicates) {
            push @pos, $pos;
        } else {
            $pos{$pos}++;
            last if $iter++ > 50_000;
        }
    }

    return map {
        my $item;
        seek $fh, $_, 0;
        chomp($item = <$fh>);
        $item;
    } ($allow_duplicates ? @pos : (keys %pos));
}

1;
# ABSTRACT: Provide a pick() implementation that creates a position index for each word

=head1 DESCRIPTION

The default L<WordList>'s C<pick()> performs a scan on the whole word list once
while collecting random items. This role provides an alternative implementation
of C<pick()> that first builds a position index for each word, then randomly
picks from the built index array.

Compared to L<WordListRole::RandomSeekPick>, the random picking is more uniform.
The downside is additional memory usage for the index.

Note: since this role's C<pick()> operates on the DATA filehandle directly
instead of using C<each_word()>, it cannot be used on dynamic wordlists.


=head1 PROVIDED METHODS

=head2 pick


=head1 SEE ALSO

L<WordListRole::RandomSeekPick>

L<WordListRole::ScanPick>

L<WordListRole>
