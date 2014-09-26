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

    my $uid = `drush \@prod uinf $username --fields=uid --format=csv`;

    chomp($uid);

    `echo '{"field_fullname":{"und":[{"value":"$fullname","format":null,"safe_value":"$fullname"}]},"force_password_change":"1"}' | drush --pipe \@prod entity-update user $uid --fields=field_fullname --json-input=-`;

    `drush \@prod user-add-role "Writer" $username`;

    echo $password;

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
                        <p>Your Reporter Magazine account has been created. Please go to <a href=\"reporter.rit.edu\">reporter.rit.edu</a> and click the Login link at the bottom of the page. Use the following credentials to login:
                        <p>Username: $username</p>
                        </p>Password: $password</p>
                        <p>Please note that you will have to change your password after your first login.</p>
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

