#!/usr/bin/perl

	# (c)2014 Gulf Interstate Engineering
	#
	# mlott@gie.com 02/07/2014
	# Fix SOGo events so they show up correctly in Exchange/Outlook
	# The main issue appears to be the order of sections in the ics attachment.

	$inqueue = "/var/spool/mqueue.in";
	$outqueue = "/var/spool/mqueue";

	use Switch;

	opendir my($dh), $inqueue;
	my @files = readdir $dh;
	closedir $dh;

	#print Dumper(@files);
	foreach $file(@files)
	{
		my $out = '';
		my $ics = '';
		my $vtz = '';
		my $vev = '';
		my $start = '';
		my $end = '';
		
		# Status 1 = start, 2 = vev, 3 = vtz, 4 = end, 5 = ics
		my $status = 1;

		if($file =~ m/df(.*?)/)
		{
			#print "Checking file $file\n";
			my $id = $file;
			$id =~ s/df//;
			$source = "$inqueue/$file";
			$qfile  = "$inqueue/qf$id";
			$target = "$outqueue/$file";

			if(!`grep "BEGIN:VCALENDAR" $source`)
			{
				# Not a vcal message.  Move df and qf to outqueue
				`/bin/mv $source $target`;
				`/bin/mv $qfile $outqueue`;
				next;
			}

			open DF, "<$source";
			foreach $line (<DF>)
			{
				if($line =~ /BEGIN:VCALENDAR/)
				{
					$startics = 1;
				}
				elsif($line =~ /BEGIN:VTIMEZONE/)
				{
					$status = 3;
				}
				elsif($line =~ /BEGIN:VEVENT/)
				{
					$status = 2;
				}
				elsif($line =~ /END:VCALENDAR/)
				{
					$status = 4;
				}

				if($line =~ /METHOD:REQUEST/)
				{
					next;
				}

				switch($status)
				{
					case 1
					{
						$start .= $line;
						if($startics == 1)
						{
							$start .= "METHOD:REQUEST\n";
							$startics = -1;
						}
					}
					case 2
					{
						$vev .= $line;
					}
					case 3
					{
						$vtz .= $line;
					}
					case 4
					{
						$end .= $line;
					}
					case 5
					{
						$ics .= $line;
					}
				}
			}
			close DF;

			$out = $start . $ics . $vtz . $vev . $end;
			# Create modified df
			open OF, ">$target";
			print OF $out;
			close OF;

			# Remove original df
			unlink $source;
			# Move qf to out queue
			`/bin/mv $qfile $outqueue >/dev/null 2>&1`;
		}
	}

	# Process the queue!
	`sendmail -C /etc/mail/sendmail.cfcron -q`;
