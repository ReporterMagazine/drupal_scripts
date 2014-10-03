#!/usr/bin/perl
use MIME::Lite;
use String::MkPasswd qw(mkpasswd);
#iterate through command line arguments
foreach(@ARGV) {
    my $username =  $_;

    $fullname =~ s/(\w+)/\u\L$1/g;

    my $email = $username.'@rit.edu';

    my $password =  mkpasswd();

    `drush \@prod user-password $username  --password="$password"`;

    my $uid = `drush \@prod uinf $username --fields=uid --format=csv`;

    chomp($uid);

    `echo '{"force_password_change":"1"}' | drush --pipe \@prod entity-update user $uid --fields=force_password_change --json-input=-`;

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
                        <p>Your Reporter Magazine account has been reset. Please go to <a href=\"reporter.rit.edu\">reporter.rit.edu</a> and click the Login link at the bottom of the page. Use the following credentials to login:
                        <p>Username: $username</p>
                        </p>Password: $password</p>
                        <p>Please note that you will have to change your password after login.</p>
                        <p>Keep track of you password!</p>
                        <p>Reporter Magazine</p>
                    </body>
                </html>";

    $msg = MIME::Lite->new(
            From     => $from,
            To       => $to,
            Subject  => $subject,
            Type     => 'text/html',
            Data     => $message,
         );
                 
    $msg->send;
}                   

