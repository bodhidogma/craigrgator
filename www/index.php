<?php # $Id: index.php 16 2009-06-08 22:33:14Z mthornbu $

	require 'configs/setup.php';
	require 'libs/Smarty.class.php';
	require 'inc/_common.php';

	error_reporting( E_ALL & ~E_NOTICE );
	ini_set( 'display_errors', 'On' );
	ini_set( 'memory_limit', '32M' );       // parsing ak_cust
	ini_set( 'max_execution_time', '120' ); // parsing ak_cust


	// --- start of page processing

	session_cache_limiter('must-revalidate');
	session_register('session');
	$session = &$_SESSION['session'];
	
	// -- base64 decode any QUERY_STRING args
	if ( ($qrystr = $_SERVER['QUERY_STRING']) != '' ) {
		$de64 = base64_decode( $qrystr );
		$en64 = base64_encode( $de64 );
		if ( $qrystr==$en64 ) { parse_str($de64,$_GET); } else { $de64 = $qrystr; }
		$_REQUEST = array_merge($_GET,$_REQUEST);
	}
	
	/// -- find page request, if not explicit, maybe implicit via AliasMatch?
	$_REQUEST['page'] = PageRequest( ALIAS_URL,$_REQUEST['page'],"templates/" );
	$session['requri'] = $_SERVER['SCRIPT_URL']."?".enc64($de64);

	// -- get a page request so we can start our request (obj::smarty)
	if ( ! $_REQUEST['page'] ) { $_REQUEST['page'] = 'Index'; }
	$obj = CreateObject( ".", $_REQUEST['page'] );

	// -- some smarty settings
	if ( FILTER_A ) { $obj->register_outputfilter( "filter_href_fix" ); }
	$obj->compile_check = true;
	$obj->force_compile = true;
#	$obj->debugging = true;

	// -- ValidateUser, LocateSite, DB connect
	call_user_func_array( 'PageSetup', array( 'site.cfg',&$obj ) );
//	PageSetup( "site.cfg", &$obj );
	// -- process the page, and dump any output
	$obj->main();

// -- eof --
