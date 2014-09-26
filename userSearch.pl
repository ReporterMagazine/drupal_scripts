#!/usr/bin/perl
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
    my $fullname;
    foreach $entr ( @entries ) {
        my $attr;
        foreach $attr ( sort $entr->attributes ) {
            # skip binary we can't handle
            next if ( $attr =~ /;binary$/ );
            $fullname = $entr->get_value($attr);
        }
    }

    $fullname =~ s/(\w+)/\u\L$1/g;

    my $email = $username.'@rit.edu';

    my $password =  mkpasswd();

    `drush \@prod user-create $username --mail="$email" --password="$password"`;

    my $uid = `drush \@prod uinf $uid --fields=uid --format=csv`;

    `echo '{"field_fullname":{"und":[{"value":"$fullname","format":null,"safe_value":"$fullname"}]}}' | drush --pipe \@prod entity-update user $username --fields=field_fullname --json-input=-`;

    `drush \@prod user-add-role "Writer" $username`;

    my $password_link = `drush \@prod uli $username`;


    $to = $email;
    $from = 'rptadmin@rit.edu';
    $subject = 'Reporter Magazine Account Creation';
    $message = "
                <html>
                    <head>
                        <style>
                             body { font-family:Arial; font-size: 14px; }
                             #header { font-weight: bold; font-size: 20px; color: white; background-color: #188F6C; text-align: center; padding: 5px;}
                        </style>
                    </head>
                    <body>
                        <h2>Reporter Magazine</h2>
                        <p>Hi $fullname,</p>
                        <p>Your Reporter Online account is ready for your first login. Click the link below to log in for the first time. Once you're in, you will be asked to set your password.</p>
                        <p><a href=\"$password_link\">$password_link</a></p>
                        <p>Happy Writing!</p>
                        <p>Reporter Magazine</p>
                    </body>
                </html>";

    $msg = MIME::Lite->new(
            From     => $from,
            To       => $to,
            Subject  => $subject,
            Data     => $message,
         );
                 
    $msg->send;
}                   

