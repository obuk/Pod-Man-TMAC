# NAME

Pod::Man::TMAC - add user's preambles.

# SYNOPSIS

       use Pod::Man::TMAC;
       my $pod2man = Pod::Man::TMAC->new();
       $pod2man->add_preamble('user.tmac');
    
       # search directories if needed
       $pod2man->search_path(\@dir);
    
       # to override Pod::Man preamble
       $pod2man->no_default_preamble(1);
    
       # use utf8 for non-ASCII characters
       $pod2man->utf8(1);

# LICENSE

Copyright (C) KUBO, Koichi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KUBO, Koichi <k@obuk.org>
