This script was created to fix a problem with SOGo vcard attachments in an older version of SOGo.

Upgrading to the latest version of SOGo also fixes the issue.  However, if like us you are unable
to upgrade for some reason, this will fix the vcard attachment so that Outlook users can accept
invites sent from SOGo using their native form.

	1. No need double-click to open "unsupported ics attachment".
	2. Event email will not appear as a draft message.

To use this script, for example in sendmail:

	1. In /etc/mail, create a sendmail.cf file for sendmail using /var/spool/mqueue as the queue location (default).
		Usually you can run make in this directory after checking sendmail.mc.

	2. Copy this file to an alternate name, e.g. /etc/mail/sendmail.cfcfron.
		a. This file will be used for a cron job to process the fixed email files.

	3. Create a directory called /var/spool/mqueue.in.

	4. Edit your sendmail.mc to add the following lines.  THis will cause sendmail to use the created
	directory for queueing (/var/spool/mqueue.in).  It also forces sendmail to consider routes as expensive and it
	will therefore only queue the mail:

define(`QUEUE_DIR',`/var/spool/mqueue.in')dnl
define(`confCON_EXPENSIVE', `True')dnl
MODIFY_MAILER_FLAGS(`RELAY', `+e')dnl
MODIFY_MAILER_FLAGS(`SMTP', `+e')dnl
MODIFY_MAILER_FLAGS(`ESMTP', `+e')dnl
MODIFY_MAILER_FLAGS(`SMTP8', `+e')dnl
define(`confTO_QUEUEWARN', `12h')dnl

	5. Run make or otherwise create the new sendmail.cf.

	6. (Re)start sendmail to have it use the new cf file.

	7. Create a cron job to run this script and process mail from mqueue.in.
		a. Processed mail will be moved to mqueue.
		b. At the end of the script, sendmail will be called with the sendmail.cfcron created above

*/5 * * * * root run-parts /usr/local/sbin/sogoicsfix.pl

Note that in the script any email not containing evidence of a vcard simply gets moved to the out queue.  You can also process
the queue in another cron job if you like.  In that case comment out the last line which calls sendmail.

