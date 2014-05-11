// editor.js
//
$(document).ready(function() {
        $('.app-layout-set').on('click', function(e) {
		var a = $(e.target);
		var layout_class = "app-layout-" + a.text().toLowerCase();
		var layout_tag = a.closest('.app-layout-top,.app-layout-bottom,.app-layout-left,.app-layout-right');
		layout_tag.removeClass("app-layout-top app-layout-bottom app-layout-left app-layout-right");
		layout_tag.addClass(layout_class);
        });
        $("[data-toggle='tab']").on('click', function(e) {
		var a = $(this);
		var target = a.data('target') || a.attr('href');
		//console.log("tab:" + target);
		a.tab("show");
		$("[data-toggle='tab']").
			filter("[data-target='" + target + "'],[href='" + target + "']").
				parent('li').addClass('active').end().
			end().not("[data-target='" + target + "'],[href='" + target + "']").
			parent('li').removeClass('active');
		e.stopPropagation();
        });
	$('textarea.main-editor').each(function() {
		CodeMirror.fromTextArea(this, {
			mode: "text/x-haml",
			vimMode: true,
			lineNumbers: true,
		})
	});
});
