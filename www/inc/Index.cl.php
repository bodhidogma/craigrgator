<?php # $Id: Index.cl.php 46 2009-06-25 19:46:00Z paulmcav $

IncludeObject('.','db_mysql');
#include "util.inc.php";

/** Index page
*
*/
class Index extends Smarty
{
	var $name = "Index";
	var $title = "Craig-r-gater";
	var $db;
	var $config;
	var $HexColors;

	function Index()
	{
		global $session; 
	
		$session['refurl'] = "page=".$this->name;

		$this->db = new db();
	}

	function main()
	{
		global $session; 

#		$this->debugging = true;

#		$_Type = 1;
#		$_Company = 1;
#		$_Mode = 1;

#		print_r( $_REQUEST);

		# import zlist into DB
		if ( isset($_REQUEST['i'])) {
	#		$this->import_zlist( $this->db );
		}
		if ( isset($_REQUEST['f'])) {
			$this->form_submit( $this->db, $_REQUEST );
		}
		$res = $this->get_stats( $this->db, $_REQUEST['s'] );
#		print_r( $res[stats] );

		$session['fdata'] = $res['recs'];

		$this->assign( array(
			'page_title' => $this->title,
			'refurl'     => "?".enc64($session['refurl']),
			'recs'       => $res['recs'],
			'ed'		=> $_REQUEST['e'],
			));

		// final process... output page
		$out = $this->fetch( $this->name.".html" );
		$this->assign( "body", $out );
		$this->display( "common.html" );
	}

	// ----------------------

	function get_stats( $db, $srt )
	{
		global $session;

		# overall stats
		$sql = "SELECT *,UNIX_TIMESTAMP(cdate) ucdate,UNIX_TIMESTAMP(sdate) usdate  FROM autos"
			." WHERE (model is null OR (model LIKE '3%' AND model NOT LIKE '3%c%'))"
#			." AND rem<3"
			." AND rem<1"
			." AND year>=2006"
			." AND miles<35000"
			." AND watch>=0"
#			." AND watch=-1"
#			." AND reject=''"
			." ORDER BY rem,cdate DESC";
#			." ORDER BY id DESC LIMIT 22";
		$db->query ($sql);
		while ($db->next_record()) {
			$row = $db->Record;

			$row[did]=$row[id];
			if ($row[rem]) {
				$row[did]=-$row[rem];
				$row[ucdate] = $row[usdate];
			}

			$ret['recs'][] = array(
				'id' => $row[id],
				'did' => $row[did],
				'watch' => $row[watch],
				'reject' => $row[reject],
				'title' => $row[title],
				'cdate' => date("M d, H:m",$row['ucdate']),
				'link' => $row[link],
				'location' => $row[location],
				'year' => $row[year],
				'make' => $row[make],
				'model' => $row[model],
				'color' => $row[color],
				'miles' => $row[miles],
				'price' => $row[price],
				'trans' => $row[trans],
				'features' => $row[features],
			);
#		print_r( $db->Record );
		}
#		print_r ($ret );
		return $ret;
	}

	function form_submit( $db, $req )
	{
		global $session;

		$fd = $req['fd'];
		$fdsrc = $session['fdata'];

		$fields = array('watch','reject','title','location','year','model','color','miles','price','features');
#		$fields = array('model','color','miles');

#		print_r( $fdsrc );

		for ($i = 0; $i < count($fd); $i++){
			$sql_upd="";
			foreach( $fields as &$fld) {
				if (isset($fd[$i][$fld]) && $fdsrc[$i][$fld] != $fd[$i][$fld] ) {
					$val = trim($fd[$i][$fld]);

					// specific field modifications:
#					if ($fld == "miles") { }

					$sql_upd .= ",$fld=\"$val\"";
#					print "$i] $fld: ".$fd[$i][$fld]."<br>";
				}
			}
			if ($sql_upd != "") {
				$sql_upd = "UPDATE autos SET id=id $sql_upd WHERE id=".$fdsrc[$i]['id'];
#				print "s: $sql_upd<br>";
				$db->query( $sql_upd );
			}
		}
	}
}

