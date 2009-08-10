<?php # $Id: Job.cl.php 48 2009-06-26 21:37:51Z paulmcav $

IncludeObject('.','db_mysql');

# curl "http://home.queda.net/netflix/?page=Job&c=co&un=&cp=0"
# curl "http://home.queda.net/netflix/?page=Job&c=ci&id=1&un=&lc=0"

/** Job page
*
*/
class Job extends Smarty
{
	var $name = "Job";
	var $title = "process update";
	var $db;
	var $config;
	var $srccfg;

	function Job()
	{
		global $session; 
	
		$session['refurl'] = "page=".$this->name;

		$this->db = new db();
		$this->config_load('site.cfg','SourceData');
		$this->srccfg = $this->get_config_vars();
#		print_var( $this->srccfg );
	}

	function main()
	{
		global $session; 

#		$this->debugging = true;
#		echo "<pre>";
		
		$cmd = $_REQUEST['c'];

		$id       = $_REQUEST['id'];
		$username = $_REQUEST['un'];
		$cpcode   = $_REQUEST['cp'];
		$lines    = $_REQUEST['lc'];
		$stat     = $_REQUEST['st'];
		$note     = $_REQUEST['nt'];
		if ($cmd == "co" ){
			$this->do_checkout( $this->db, $id, $username, $cpcode, $note );
		}
		else if ($cmd == "ci" ){
			$this->do_checkin( $this->db, $id, $username, $lines, $stat, $note );
		}
		else if ($cmd == "rst" ){
			$this->do_reset( $this->db, $id, $username, $cpcode );
		}
		# verify check-out
		else if ($cmd == "vo" ){
			$this->do_verify_out( $this->db, $stat, $stat, $lines );
		}
		# verify check-in
		else if ($cmd == "vi" ){
		}
		else {
			print "0\n";
		}
		echo "<a href=\".\">home</a>\n";

		$this->assign( array(
			'page_title' => $this->title,
			'refurl'     => "?".enc64($session['refurl']),
			'head_title' => 'Job Page',
			));

		// final process... output page
//		$out = $this->fetch( $this->name.".html" );
//		$this->assign( "body", $out );
//		$this->display( "common.html" );
	}

	// ----------------------

	function do_checkout( $db, $job, $owner, $qid, $note )
	{
		$gotlock = 0;
		$trycnt = 0;
		$maxtry = 20;

# print "a: $cpcode, $owner, $job <br>\n";
		if ($owner=="") {
			$owner = $_SERVER['REMOTE_ADDR'];
		}
		# loop trying to get a lock on (a/the) job
		do {
			$db->lock( "queue_order","read" );
			# determine which queue order to process next
			$sql = "SELECT * FROM queue_order "; #"WHERE status=0 ";
			$sql .= "ORDER by count,fieldval LIMIT 1";
			$db->query( $sql );
			if ( ! $db->next_record()) {
				$db->unlock();
				$gotlock = -1;
				print "co\t-1\t-end-\t\n";
				return;
			}
			$Qrow = $db->Record;

			# try and retrieve an available job from the list
			$db->lock( "joblist" );
			$sql = "SELECT * FROM joblist WHERE 1 AND dst_host='".$Qrow['fieldval']."' ";
			if ($job<1) {
				$sql .= "AND status=0 AND owner='' ";
			}
			else {
				$sql .= "AND id=$job ";
			}
#			$sql .= "AND files <100 ";	# testing
#			$sql .= "AND files <100 ORDER BY list DESC ";		# testing
#			$sql .= "AND id<=150 ";	# testing
			$sql .= "LIMIT 1";

# print "sql: $sql <br>\n";
			$db->query( $sql );
			if (! $db->next_record()) {
 print "missed joblist\n";

#				$gotlock = -1;
#				print("co\t-2\t-end-\t\n");
#				return;
				usleep(10);
				continue;
			}
			$row = $db->Record;
# print_r( $row );
			$sql = "UPDATE joblist SET status=1,owner='$owner',queue_id='$qid',"
				."cout=NOW() WHERE ";
			if ($job<1) {
				$sql .= "status=0 AND owner='' AND ";
			}
			$sql .= "id=".$row['id'];
# print "sql: $sql <br>\n";
			$db->lock("joblist","write");
			$res = $db->query( $sql  );

			# no specific job selected
			if ($job<1) {
				$gotlock = $db->affected_rows();
}
			else {
				$gotlock = 1;
			}
			$trycnt++;
		} while(!$gotlock && $trycnt< $maxtry);

		if ($trycnt == $maxtry) {
			print "co\t0\nfailed($trycnt) to get lock<br>\n";
			return -1;
		}

		# update queue_order count
		$db->lock( "queue_order", "write" );
		$sql = "UPDATE queue_order SET count=count+1 where id=".$Qrow['id'];
		$db->query( $sql );

		#unlock tables
		$db->unlock();

#		print "<hr>cnt: $trycnt<br>"; print_r ($row );
		printf( "co\t%d\t%s\t%s\t%s\t%d\t\n", $row['id'],
		   	$row['src_url'], $row['dst_host'],$row['dst_path'], $row['size'] );
	
		return $row;
	}

	function do_checkin( $db, $id, $owner, $files, $stat, $note )
	{
		if ($owner=="") {
			$owner = $_SERVER['REMOTE_ADDR'];
		}
		if ($id=="" || $files=="") {
			print "0\nfailed to checkin.  Missing id/lines<br>\n";
			return -1;
		}

		if ($stat=="") {
			$stat = 2;
		}
		$sql = "UPDATE joblist SET status=$stat,cin=NOW(),note='$note' WHERE "
#			."status=1 AND "
			."id=$id "
			."AND owner='$owner' "
#			."AND files=$files "
			;
		$db->query( $sql );
		$ok = $db->affected_rows();

		print "ci\t$ok\t$id\t$owner\t$files\n";
	}

	function do_reset( $db, $id, $owner, $cpcode, $note )
	{
		if ($owner=="") {
			$owner = $_SERVER['REMOTE_ADDR'];
		}
		if ($note="") {
			$note = "rst";
		}
		$sql = "UPDATE joblist SET status=0,cin=0,cout=0,owner='',note='$note' WHERE "
			."status=1 "
			."AND owner='$owner' ";
		if ($id>0) {
			$sql .= "AND id=$id ";
		}
		if ($cpcode>0) {
			$sql .="AND cpcode=$cpcode ";
		}
		$db->query( $sql );
		$ok = $db->affected_rows();

		print "rst\t$ok\t$id\t$owner\t0\n";
	}

	function do_verify_out( $db, $stat, $start=0, $rows=100 )
	{
		$sql = "SELECT count(id) from joblist WHERE status=2";
		$db->query( $sql );
		$db->next_record();
	
		$num_rows = $db->Record[0];

#		$rows = 5;
		if ($rows > $num_rows) { $rows = $num_rows; }

		$sql = "SELECT * from joblist where status=2";

		if ($rows>0 && $start < $num_rows) {
			$db->limit_query( $sql, $start, '','', $rows );
		}
		print "vo\t$num_rows\t$start\t$rows\n";

		print "ID\tSIZE\tDST_FILE\tSRC_FILE\n";
		while ($db->next_record()) {
			$row = $db->Record;

			printf( "%d\t%d\t%s.download.akamai.com%s\t%s\n",
				$row[id],
				$row[size],
				$row[dst_host],
				$row[dst_path],
				$row[src_url]
			);
		}
	}

}

