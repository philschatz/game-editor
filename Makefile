all: minify

minify:
	cat flatui/js/jquery-1.8.2.min.js flatui/js/jquery-ui-1.10.0.custom.min.js flatui/js/jquery.dropkick-1.0.0.js flatui/js/custom_checkbox_and_radio.js flatui/js/custom_radio.js flatui/js/jquery.tagsinput.js flatui/js/bootstrap.js flatui/js/jquery.placeholder.js > flatui-deps.js
