#!/usr/bin/perl
#!~/perl5
use Net::LDAP;
use Net::LDAP::Entry;
use MIME::Lite;
use String::MkPasswd qw(mkpasswd);
#iterate through command line arguments
foreach(@ARGV) {
    my $username =  $_;

    my $ldap = Net::LDAP->new ("ldap.rit.edu") or die "$@";

    my $attrs = [ 'cn' ];

    my $result = $ldap->search ( 	base => "ou=people,dc=rit,dc=edu",
	    			filter => "uid=$username",
		    		attrs => $attrs,
			    	);

    my @entries = $result->entries;
    #check
    if(scalar(@entries) != 1) {
        print "$username not found.\n";
        break;
    }

    my $entr;
    my $user;
    foreach $entr ( @entries ) {
        my $attr;
        foreach $attr ( sort $entr->attributes ) {
            # skip binary we can't handle
            next if ( $attr =~ /;binary$/ );
            $user = $entr->get_value($attr);
        }
    }

    $user =~ s/(\w+)/\u\L$1/g;

    $email = $username.'@rit.edu';

    $password =  mkpasswd();

    `drush \@prod user-create $username --mail="$email" --password="$password"`;

    $uid = `drush \@prod uinf $uid --fields=uid --format=csv`;

    `echo '{"field_fullname":{"und":[{"value":"$user","format":null,"safe_value":"$user"}]}}' | drush --pipe \@prod entity-update user $uid --fields=field_fullname --json-input=-`;

    `drush \@prod user-add-role "Writer" $username`;

    $password_link = `drush \@prod uli $username`;


    $to = $email;
    $from = 'rptadmin@rit.edu';
    $subject = 'Reporter Magazine Web Account';
    $message = "Hi $user! Please navigate to $password_link to login to the website for the first time.";

    $msg = MIME::Lite->new(
            From     => $from,
            To       => $to,
            Subject  => $subject,
            Data     => $message,
         );
                 
    $msg->send;
}                   

