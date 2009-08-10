<?php # $Id: Help.cl.php 16 2009-06-08 22:33:14Z mthornbu $

/** Help page
*
*/
class Help extends Smarty
{
	var $name = "Help";
	var $title = "Competition Mapping";
#	var $db;
#	var $config;
#	var $HexColors;

	function Help()
	{
		global $session; 
	
		$session['refurl'] = "page=".$this->name;
	}

	function main()
	{
		global $session; 

#		$this->debugging = true;

#		$_Type = 1;
#		$_Company = 1;
#		$_Mode = 1;

		$this->assign( array(
			'page_title' => $this->title,
			'refurl'     => "?".enc64($session['refurl']),
			'head_title' => 'Competition Mapping',
			));

		// final process... output page
		$out = $this->fetch( $this->name.".html" );
		$this->assign( "body", $out );
		$this->display( "common.html" );
	}

	// ----------------------
}

