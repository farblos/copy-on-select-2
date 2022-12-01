window.addEventListener(
  'mouseup',
  function( e ) {
    if ( (document.getSelection().toString().length > 0) &&
         ((new URL( document.URL )).hostname !== "docs.google.com") ) {
      document.execCommand( 'copy' );
    }
  },
  false
);
