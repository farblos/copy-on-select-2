window.addEventListener(
	'mouseup',
	function() {
		if (document.getSelection().toString() != '') {
			document.execCommand('copy');
		}
	},
	false
);