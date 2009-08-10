<?php # $Id: _common.php 16 2009-06-08 22:33:14Z mthornbu $

	# common support functions
	
// generic page setup stuff
function PageSetup( $cfg, $obj )
{
	global $session;

	// -- check to see if we want a connection to the db
	if ( get_class( $obj->db ) == "db" ) {
		$obj->config_read_hidden = TRUE;
		$obj->config_load( $cfg,'DB' );
		$obj->config_read_hidden = FALSE;
		$dbv = $obj->get_config_vars( );
		$obj->clear_config();
#		$obj->config = $dbv;
#		print_var( $dbv );
		$obj->db->connect(
			$dbv['database'], $dbv['host'], $dbv['user'], $dbv['password'] );
	}	

	$obj->config_load($cfg );
	$obj->config = $obj->get_config_vars();

}

// determine if we are being called via Alias Match, or a ?page=<request>
//
function PageRequest( $aliasurl, $page, $tpl="" )
{
	global $HTTP_SERVER_VARS;

	if ( ! $page ) {
		$script = $HTTP_SERVER_VARS['SCRIPT_URL'];
		$sub = substr($script,0,strlen($aliasurl));

		// does SCRIPT_URL match base of 'alias_url'?, take remaining part
		if ( $sub == $aliasurl) {
			if (substr($sub,-1) != "/"){ $sub .= "/"; }

			$page = substr($script,strlen($sub));
			// has .html extension, handle it.
			if ($pos = strpos($page,".html")) {
#	echo "have '.'<br>";
				$page = substr($page,0,$pos);
			}
			// not .html, but has some extension, passthru
			else if (strpos($page,".")) {
				if ( file_exists( $tpl.$page ) ) {
					Header( "Content-type: ".mime_content_type( $tpl.$page ));
					readfile( $tpl.$page ); die;
				}
				else {
					error404( "$tpl$page" );
				}
#	echo "some image: $tpl$page<br"; die;
			}
			// assume it should be .html
			else {
#	echo "no .html<br>";
				$page .= "Index";
			}
#	echo "SCRIPT_URL: ".$script. "<br>";
#	echo "sub: $sub, aliasurl: ".$globs['aliasurl']."<br>";
#	echo "Page: $page<br>";
		}
	}
	return $page;
}

if (!function_exists ("mime_content_type")) {
 function mime_content_type ($file) {
  return exec ("file -bi $file");
 }
}

function error404( $page )
{
	@header("HTTP/1.0 404 Not Found");
	echo "<p><h2>Error 404</h2>File not found: ";
	echo "<i><font color=red>$page</font></i><br>";
}


# super eneric class to display an html page.
class HtmlPage extends Smarty
{
	var $data;

	function HtmlPage( $file ) {
		$fdata = @file("templates/".$file.".html");
		if (!$fdata ) {
			$fdata = @file("templates/404.html");
			if (!$fdata) {
				error404( "$file.html" );
				die;
			}
		}
		$this->data = implode("",$fdata);
	}

	function main() {
		global $globs;

		if ($globs['filtpage'] == TRUE) {
			print filter_href_fix( $this->data );
		}
		else {
			print $this->data ;
		}
	}
}

function IncludeObject($root, $obj)
{
	$path = '';
	if ( !($class = substr(strrchr($obj, '/'),1)) ) {
		$class = $obj;
	}
	else {
		$path = '/'.substr($obj,0,strrpos($obj,'/'));
	}
#		$path .= "/inc";
	$path = "/inc".$path;
	
	if ( class_exists($class) ) {
		return 0;
	}
	
	$file = $root.$path.'/'.$class.'.cl.php';

	if ( file_exists($file) ) {
		include($file);
		return $class;
	}
	return '';
}

function CreateObject($root, $obj, $parms='_F_' )
{
	$class = IncludeObject($root,$obj);

	# if no class was found, try a generic html page
	if ( $class=='') {
		$class = "HtmlPage";
#			$class = IncludeObject("Page");
		$parms = array($obj);
	}

	$code = '$ret = new '.$class.'(';
	
	for ($i=0;$parms != '_F_' && $i<count($parms);$i++) {
		$code .= ($i ? ',':'')."'".$parms[$i]."'";
	}

	$code .= ');';
	eval( $code );
	return $ret;
}

function slashes( $str, $n=1 )
{
	if ( !$n || ini_get('magic_quotes_gpc')==1
		|| ini_get('magic_quotes_runtime')==1
	   ) {
		return $str;
	}
	else {
		return addslashes( $str );
	}
}

function filter_href_fix( $str )
{
	$reg = "/(href\\s*=\\s*)\"([^.?=]\\w*)(\.html)[^?]?\"/sim";
	$rep = "\$1\"?page=\$2\"";

	return preg_replace( $reg , $rep , $str , -1 );
}

// base64 encode function
function enc64( $str ){
	if ( ENCODE_64 ) { return base64_encode($str); } else 
	{ return $str; }
}

function cfg_to_array( $cfg, $var )
{
	$lst = explode( " ",$cfg[$var] );
	while (list($k,$v) = each($lst)) {
		$cfg_lst[$v] = $cfg[$var."_$v"];
	}
	return $cfg_lst;
}

function print_var($var,$m=0)
{
	echo "<pre>";
	if ($m==0) print_r($var);
	else var_dump($var);
   	echo "</pre>";
}

